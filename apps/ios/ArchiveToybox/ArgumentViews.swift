import SwiftUI

struct ArgumentHomeView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("好好吵架").font(.largeTitle.bold())
                    Text("练习把话说清楚，也复盘为什么没说清楚。").foregroundStyle(.secondary)
                }.listRowBackground(Color.clear)
            }
            Section {
                NavigationLink { ArgumentSimulationView() } label: {
                    ArgumentModeRow(title: "模拟练习", subtitle: "描述冲突场景，让 AI 扮演对方。", symbol: "bubble.left.and.bubble.right")
                }
                NavigationLink { ArgumentAnalysisView() } label: {
                    ArgumentModeRow(title: "吵架分析", subtitle: "粘贴聊天记录，分析这次争执。", symbol: "doc.text.magnifyingglass")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle("好好吵架")
    }
}

struct ArgumentModeRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.title3.bold()).foregroundStyle(.purple)
                .frame(width: 42, height: 42).background(.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 8)
    }
}

struct ArgumentSimulationView: View {
    @EnvironmentObject private var appState: AppState
    @State private var opponentRole = "老板"
    @State private var relationship = "上下级"
    @State private var background = "老板临时改需求，让我今晚重做方案"
    @State private var goal = "表达边界"
    @State private var style = "强势"
    @State private var isLoading = false

    var body: some View {
        Form {
            Section("创建模拟练习") {
                TextField("对方是谁", text: $opponentRole)
                TextField("你们的关系", text: $relationship)
                TextField("发生了什么", text: $background, axis: .vertical)
                TextField("你想练习什么", text: $goal)
                TextField("对方说话风格", text: $style)
            }
            Section {
                NavigationLink("开始模拟") {
                    if isLoading {
                        ProgressView("创建会话...")
                    } else {
                        ArgumentChatView(sessionId: "", openingMessage: "", setupSummary: "")
                    }
                }
                .disabled(isLoading)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle("模拟练习")
        .background(
            NavigationLink(isActive: .constant(false)) {
                EmptyView()
            } label: { EmptyView() }
        )
        .safeAreaInset(edge: .bottom) {
            NavigationLink {
                PracticeSessionLoader(
                    setup: .init(
                        opponentLabel: opponentRole,
                        relationship: relationship,
                        whatHappened: background,
                        practiceGoal: goal,
                        opponentStyle: style
                    )
                )
            } label: {
                Text("开始模拟")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.cyan, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.black)
                    .padding()
            }
        }
    }
}

struct PracticeSessionLoader: View {
    @EnvironmentObject private var appState: AppState
    let setup: PracticeSetupPayload
    @State private var session: PracticeSessionCreated?
    @State private var error: String?

    var body: some View {
        Group {
            if let session {
                ArgumentChatView(
                    sessionId: session.sessionId,
                    openingMessage: session.openingMessage,
                    setupSummary: "对方：\(setup.opponentLabel) · 关系：\(setup.relationship)"
                )
            } else if let error {
                ContentUnavailableView("创建失败", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                ProgressView("正在创建模拟练习...")
            }
        }
        .task {
            do {
                session = try await appState.api.createPracticeSession(setup)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

struct ArgumentChatView: View {
    @EnvironmentObject private var appState: AppState
    let sessionId: String
    let openingMessage: String
    let setupSummary: String
    @State private var messages: [PracticeMessageDTO] = []
    @State private var draft = ""
    @State private var review: ArgumentReview?
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(setupSummary).font(.caption).foregroundStyle(.secondary)
                        .padding().background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                    if messages.isEmpty, !openingMessage.isEmpty {
                        bubble("AI：\(openingMessage)", isUser: false)
                    }
                    ForEach(messages) { message in
                        bubble(message.role == "user" ? "我：\(message.content)" : "AI：\(message.content)", isUser: message.role == "user")
                    }
                }.padding()
            }
            HStack {
                TextField("输入你的回应", text: $draft).textFieldStyle(.roundedBorder)
                Button("发送") { Task { await send() } }
                    .buttonStyle(.borderedProminent).tint(.cyan).disabled(isSending)
            }.padding(.horizontal)
            NavigationLink("结束并生成复盘") {
                if let review {
                    ArgumentReviewView(review: review)
                } else {
                    ReviewLoader(sessionId: sessionId)
                }
            }
            .buttonStyle(.bordered).padding(.bottom)
        }
        .background(AppBackground())
        .navigationTitle("模拟中")
    }

    private func bubble(_ text: String, isUser: Bool) -> some View {
        Text(text)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            .background(isUser ? Color.cyan.opacity(0.18) : Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }

    private func send() async {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        defer { isSending = false }
        do {
            let message = try await appState.api.sendPracticeMessage(sessionId: sessionId, content: draft)
            messages.append(.init(id: UUID().uuidString, role: "user", content: draft))
            messages.append(message)
            draft = ""
            Feedback.tap()
        } catch {
            messages.append(.init(id: UUID().uuidString, role: "assistant", content: "网络异常，请稍后再试。"))
        }
    }
}

struct ReviewLoader: View {
    @EnvironmentObject private var appState: AppState
    let sessionId: String
    @State private var review: ArgumentReview?
    @State private var error: String?

    var body: some View {
        Group {
            if let review {
                ArgumentReviewView(review: review)
            } else if let error {
                ContentUnavailableView("复盘失败", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                ProgressView("正在生成复盘...")
            }
        }
        .task {
            do {
                let dto = try await appState.api.finishPractice(sessionId: sessionId)
                review = ArgumentReview(from: dto)
                await appState.refreshToyboxHome()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

struct ArgumentAnalysisView: View {
    @EnvironmentObject private var appState: AppState
    @State private var chatText = ""
    @State private var userSide = "A"
    @State private var relationship = "同事"
    @State private var analysisGoal = "看清情绪升级点"
    @State private var showPrivacyWarning = false
    @State private var navigateToReport = false
    @State private var reportData: AnalysisReportDTO?

    var body: some View {
        Form {
            Section {
                Text("请尽量删除姓名、电话、地址、公司名等个人隐私信息后再上传。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("聊天记录") {
                TextField("请粘贴聊天记录", text: $chatText, axis: .vertical).lineLimit(8, reservesSpace: true)
                Picker("我是哪一方", selection: $userSide) {
                    Text("A").tag("A")
                    Text("B").tag("B")
                }
                Picker("你们的关系", selection: $relationship) {
                    ForEach(["同事", "上下级", "朋友", "伴侣", "家人", "室友", "其他"], id: \.self) { Text($0).tag($0) }
                }
                TextField("分析目标", text: $analysisGoal)
            }
            Section {
                Button("开始分析") { showPrivacyWarning = true }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle("吵架分析")
        .sheet(isPresented: $showPrivacyWarning) {
            PrivacyWarningSheet(confirm: analyze)
        }
        .navigationDestination(isPresented: $navigateToReport) {
            if let reportData {
                ArgumentAnalysisReportView(report: reportData)
            }
        }
    }

    private func analyze() {
        Task {
            do {
                let created = try await appState.api.createAnalysis(.init(
                    chatText: chatText,
                    selfSide: userSide,
                    relationship: relationship,
                    analysisGoal: analysisGoal,
                    privacyAcknowledged: true
                ))
                reportData = created.report
                navigateToReport = true
            } catch {
                appState.lastError = error.localizedDescription
            }
        }
    }
}

struct PrivacyWarningSheet: View {
    let confirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("上传前请确认").font(.title2.bold())
                Text("请删除聊天记录中的姓名、电话、地址、公司名等隐私信息。内容仅用于本次分析。")
                    .foregroundStyle(.secondary)
                Button("我已处理隐私信息，开始分析") {
                    dismiss()
                    confirm()
                }
                .buttonStyle(.borderedProminent).tint(.cyan)
                Spacer()
            }
            .padding(24)
        }
    }
}

struct ArgumentAnalysisReportView: View {
    let report: AnalysisReportDTO

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("一句话总结").font(.title2.bold())
                Text(report.oneLiner).foregroundStyle(.secondary)
                ReportBlock(title: "争吵起因", body: report.rootCause)
                ReportBlock(title: "情绪升级点", body: report.escalationPoints)
                ReportBlock(title: "双方表达模式", body: report.expressionPatterns)
                ReportBlock(title: "你做得好的地方", body: report.userStrengths)
                ReportBlock(title: "可以优化的地方", body: report.userImprovements)
                ReportBlock(title: "更好的表达版本", body: report.betterPhrasing)
                ReportBlock(title: "下一句怎么回", body: report.nextReply)
                ReportBlock(title: "最终建议", body: report.finalAdvice)
            }.padding(20)
        }
        .background(AppBackground())
        .navigationTitle("分析报告")
    }
}

struct ReportBlock: View {
    let title: String
    let bodyText: String

    init(title: String, body: String) {
        self.title = title
        self.bodyText = body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(bodyText).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }
}

extension AnalysisCreatedDTO: Identifiable {}
