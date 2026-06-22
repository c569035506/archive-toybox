import SwiftUI

@main
struct ArchiveToyboxApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
                .task { await appState.bootstrap() }
                .sheet(isPresented: Binding(
                    get: { !appState.hasAcceptedPrivacy },
                    set: { _ in }
                )) {
                    PrivacyConsentSheet()
                        .environmentObject(appState)
                }
        }
    }
}

struct PrivacyConsentSheet: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("隐私提示")
                        .font(.largeTitle.bold())
                    Text("《存档玩具盒》会收集提供服务所需的最少信息。上传聊天记录前，请删除姓名、电话、地址、公司名等隐私信息。")
                        .foregroundStyle(.secondary)
                    Text("本产品不提供医疗、法律或心理咨询服务，也不承诺任何现实结果。")
                        .foregroundStyle(.secondary)
                    Button("我已阅读并同意") {
                        appState.acceptPrivacy()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .accessibilityIdentifier("privacyAcceptButton")
                }
                .padding(24)
            }
        }
        .interactiveDismissDisabled()
    }
}
