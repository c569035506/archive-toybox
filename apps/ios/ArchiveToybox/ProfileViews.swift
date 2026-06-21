import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var analysisItems: [AnalysisListItem] = []
    @State private var legalDoc: LegalDocument?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(appState.profile?.nickname ?? "玩具盒用户").font(.title.bold())
                        Text("短 ID：\(appState.profile?.shortId ?? "—")").foregroundStyle(.secondary)
                        Text("总功德 \(appState.profile?.totalMerit ?? 0)").foregroundStyle(.mint)
                    }.padding(.vertical, 8)
                }
                Section("分析记录") {
                    NavigationLink("查看吵架分析历史") {
                        AnalysisHistoryView(items: analysisItems)
                    }
                }
                Section("合规") {
                    NavigationLink("隐私政策") { LegalWebView(docPath: "privacy-policy") }
                    NavigationLink("用户协议") { LegalWebView(docPath: "terms") }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle("我的")
            .task {
                analysisItems = (try? await appState.api.listAnalysis()) ?? []
            }
            .refreshable {
                await appState.refreshProfile()
                analysisItems = (try? await appState.api.listAnalysis()) ?? []
            }
        }
    }
}

struct AnalysisHistoryView: View {
    @EnvironmentObject private var appState: AppState
    @State var items: [AnalysisListItem]

    var body: some View {
        List {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.oneLiner).font(.headline)
                    Text("\(item.relationship) · \(item.analysisGoal)").font(.caption).foregroundStyle(.secondary)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        Task {
                            try? await appState.api.deleteAnalysis(id: item.id)
                            items.removeAll { $0.id == item.id }
                        }
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("分析记录")
    }
}

struct LegalWebView: View {
    @EnvironmentObject private var appState: AppState
    let docPath: String
    @State private var document: LegalDocument?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(document?.title ?? "加载中").font(.title.bold())
                Text(document?.content ?? "").foregroundStyle(.secondary)
            }.padding(20)
        }
        .background(AppBackground())
        .task {
            document = try? await appState.api.fetchLegal(doc: docPath)
        }
    }
}
