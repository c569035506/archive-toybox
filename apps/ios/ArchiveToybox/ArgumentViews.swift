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
                NavigationLink { ArgumentCharacterHubView() } label: {
                    ArgumentModeRow(title: "模拟练习", subtitle: "创建或选择 AI 角色，开始对话练习。", symbol: "bubble.left.and.bubble.right")
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

struct ArgumentCharacterHubView: View {
    @EnvironmentObject private var appState: AppState
    @State private var characters: [PracticeCharacterDTO] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("正在加载角色…")
            } else if let error {
                ContentUnavailableView("加载失败", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if characters.isEmpty {
                ContentUnavailableView {
                    Label("还没有练习角色", systemImage: "person.crop.circle.badge.plus")
                } description: {
                    Text("先创建一个 AI 对方，设定身份和性格，再开始模拟对话。")
                } actions: {
                    NavigationLink {
                        ArgumentCharacterCreateView()
                    } label: {
                        Text("创建角色")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .accessibilityIdentifier("practiceCreateCharacterButton")
                }
            } else {
                List {
                    Section {
                        NavigationLink {
                            ArgumentCharacterCreateView()
                        } label: {
                            Label("创建新角色", systemImage: "plus.circle.fill")
                                .foregroundStyle(.cyan)
                        }
                        .accessibilityIdentifier("practiceCreateCharacterButton")
                    }
                    Section("已有角色") {
                        ForEach(characters) { character in
                            NavigationLink {
                                ArgumentPracticeSetupView(character: character)
                            } label: {
                                PracticeCharacterRow(character: character)
                            }
                            .accessibilityIdentifier("practiceCharacterRow-\(character.id)")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(AppBackground())
        .navigationTitle("选择角色")
        .refreshable { await loadCharacters() }
        .onAppear { Task { await loadCharacters() } }
    }

    private func loadCharacters() async {
        isLoading = characters.isEmpty
        error = nil
        defer { isLoading = false }
        do {
            characters = try await appState.api.listPracticeCharacters()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct PracticeCharacterRow: View {
    let character: PracticeCharacterDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(character.name).font(.headline)
                Spacer()
                Text(character.voiceProfile.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !character.relationship.isEmpty {
                Text(character.relationship).font(.caption).foregroundStyle(.secondary)
            }
            if !character.personalityDesc.isEmpty {
                Text(character.personalityDesc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if character.sessionCount > 0 {
                Text("已练习 \(character.sessionCount) 次")
                    .font(.caption2)
                    .foregroundStyle(.cyan)
            }
            if !character.memorySummary.isEmpty {
                Text("记忆：\(character.memorySummary)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ArgumentCharacterCreateView: View {
    @EnvironmentObject private var appState: AppState
    @State private var name = "老板"
    @State private var relationship = "上下级"
    @State private var style = "强势"
    @State private var identityDesc = ""
    @State private var personalityDesc = ""
    @State private var voiceGender: OpponentVoiceGender = .female
    @State private var voiceAge: OpponentVoiceAge = .middle
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var createdCharacter: PracticeCharacterDTO?

    var body: some View {
        Form {
            if let saveError {
                Text(saveError).font(.footnote).foregroundStyle(.orange)
            }
            Section("角色是谁") {
                TextField("称呼/角色", text: $name)
                TextField("你们的关系", text: $relationship)
                TextField("身份描述", text: $identityDesc, axis: .vertical)
                    .lineLimit(3...6)
                Text("职业、处境、说话习惯等，越具体 AI 越像这个人。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("性格与声音") {
                TextField("说话风格", text: $style)
                TextField("性格描述", text: $personalityDesc, axis: .vertical)
                    .lineLimit(3...8)
                Text("急躁、好面子、爱回避… AI 会按这个性格模拟。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Picker("AI 声音", selection: $voiceGender) {
                    ForEach(OpponentVoiceGender.allCases) { gender in
                        Text(gender.title).tag(gender)
                    }
                }
                Picker("AI 年龄", selection: $voiceAge) {
                    ForEach(OpponentVoiceAge.allCases) { age in
                        Text(age.title).tag(age)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle("创建角色")
        .safeAreaInset(edge: .bottom) {
            if let createdCharacter {
                NavigationLink {
                    ArgumentPracticeSetupView(character: createdCharacter)
                } label: {
                    Text("开始练习")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.cyan, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.black)
                        .padding()
                }
                .accessibilityIdentifier("practiceStartButton")
            } else {
                Button {
                    Task { await saveCharacter() }
                } label: {
                    Text(isSaving ? "保存中…" : "保存角色")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.cyan, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.black)
                        .padding()
                }
                .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("practiceSaveCharacterButton")
            }
        }
    }

    private func saveCharacter() async {
        isSaving = true
        saveError = nil
        defer { isSaving = false }
        do {
            let character = try await appState.api.createPracticeCharacter(.init(
                name: name,
                relationship: relationship,
                opponentStyle: style,
                identityDesc: identityDesc,
                personalityDesc: personalityDesc,
                voiceGender: voiceGender,
                voiceAge: voiceAge
            ))
            createdCharacter = character
        } catch {
            saveError = error.localizedDescription
        }
    }
}

struct ArgumentPracticeSetupView: View {
    let character: PracticeCharacterDTO
    @State private var relationship = ""
    @State private var background = "老板临时改需求，让我今晚重做方案"
    @State private var goal = "表达边界"
    @State private var interactionMode: PracticeInteractionMode = .text
    @AppStorage("practiceVoiceContinuousMode") private var continuousConversation = true

    var body: some View {
        Form {
            Section("角色") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(character.name).font(.headline)
                    if !character.identityDesc.isEmpty {
                        Text(character.identityDesc).font(.subheadline).foregroundStyle(.secondary)
                    }
                    if !character.personalityDesc.isEmpty {
                        Text("性格：\(character.personalityDesc)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text(character.voiceProfile.summary)
                        .font(.caption)
                        .foregroundStyle(.cyan)
                    if !character.memorySummary.isEmpty {
                        Text("历史记忆：\(character.memorySummary)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if character.sessionCount > 0 {
                        Text("将根据过往练习延续角色表现。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section("本次练习") {
                Picker("练习方式", selection: $interactionMode) {
                    ForEach(PracticeInteractionMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                if interactionMode == .voice {
                    Toggle("连续对话", isOn: $continuousConversation)
                }
                TextField("你们的关系（可覆盖）", text: $relationship)
                TextField("发生了什么", text: $background, axis: .vertical)
                TextField("你想练习什么", text: $goal)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle("开始练习")
        .onAppear {
            if relationship.isEmpty {
                relationship = character.relationship
            }
        }
        .safeAreaInset(edge: .bottom) {
            NavigationLink {
                PracticeSessionLoader(
                    character: character,
                    scenario: .init(
                        relationship: relationship,
                        whatHappened: background,
                        practiceGoal: goal
                    ),
                    interactionMode: interactionMode
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
            .accessibilityIdentifier("practiceStartButton")
        }
    }
}

struct PracticeSessionLoader: View {
    @EnvironmentObject private var appState: AppState
    let character: PracticeCharacterDTO
    let scenario: PracticeScenarioPayload
    let interactionMode: PracticeInteractionMode
    @State private var session: PracticeSessionCreated?
    @State private var error: String?

    var body: some View {
        Group {
            if let session {
                switch interactionMode {
                case .text:
                    ArgumentChatView(
                        sessionId: session.sessionId,
                        openingMessage: session.openingMessage,
                        setupSummary: practiceSummary
                    )
                case .voice:
                    ArgumentVoicePracticeView(
                        sessionId: session.sessionId,
                        openingMessage: session.openingMessage,
                        setupSummary: practiceSummary,
                        voiceProfile: character.voiceProfile
                    )
                }
            } else if let error {
                ContentUnavailableView("创建失败", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                ProgressView("正在创建模拟练习...")
            }
        }
        .task {
            do {
                session = try await appState.api.createPracticeSession(
                    characterId: character.id,
                    scenario: scenario
                )
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private var practiceSummary: String {
        "对方：\(character.name) · 关系：\(scenario.relationship) · \(character.voiceProfile.summary)"
    }
}

enum PracticeInteractionMode: String, CaseIterable, Identifiable {
    case text
    case voice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: "文字"
        case .voice: "语音"
        }
    }

    var subtitle: String {
        switch self {
        case .text: "打字或点麦克风把语音转成文字后发送。"
        case .voice: "对方会朗读台词；可分多段说完，停稳或点「说完了」后再回复。"
        }
    }
}

struct ArgumentChatView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var speechRecognizer = PracticeSpeechRecognizer()
    let sessionId: String
    let openingMessage: String
    let setupSummary: String
    @State private var messages: [PracticeMessageDTO] = []
    @State private var draft = ""
    @State private var review: ArgumentReview?
    @State private var isSending = false
    @State private var sendError: String?

    var body: some View {
        VStack(spacing: 12) {
            if let sendError {
                Text(sendError)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            if let speechError = speechRecognizer.errorMessage {
                Text(speechError)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            if speechRecognizer.isListening {
                Text("正在听你说话…")
                    .font(.footnote)
                    .foregroundStyle(.cyan)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
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
            HStack(spacing: 10) {
                TextField("输入你的回应", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("practiceReplyField")
                Button {
                    Task {
                        await speechRecognizer.toggleListening(currentDraft: draft) { updated in
                            draft = updated
                        }
                    }
                } label: {
                    Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
                .tint(speechRecognizer.isListening ? .red : .cyan)
                .disabled(isSending)
                .accessibilityIdentifier("practiceVoiceInputButton")
                .accessibilityLabel(speechRecognizer.isListening ? "停止语音输入" : "语音输入")

                Button("发送") { Task { await send() } }
                    .buttonStyle(.borderedProminent).tint(.cyan).disabled(isSending || speechRecognizer.isListening)
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
        .onDisappear {
            speechRecognizer.stopListening()
        }
    }

    private func bubble(_ text: String, isUser: Bool) -> some View {
        Text(text)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            .background(isUser ? Color.cyan.opacity(0.18) : Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }

    private func send() async {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        speechRecognizer.stopListening()
        isSending = true
        sendError = nil
        defer { isSending = false }
        let outgoing = draft
        do {
            let message = try await appState.api.sendPracticeMessage(sessionId: sessionId, content: outgoing)
            messages.append(.init(id: UUID().uuidString, role: "user", content: outgoing))
            messages.append(message)
            draft = ""
            Feedback.tap()
        } catch {
            sendError = error.localizedDescription
        }
    }
}

struct ArgumentVoicePracticeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var speechRecognizer = PracticeSpeechRecognizer()
    @StateObject private var speechSynthesizer = PracticeSpeechSynthesizer()
    @AppStorage("practiceVoiceContinuousMode") private var continuousMode = true
    @AppStorage("practiceVoiceSpeechRate") private var speechRate = 0.95
    let sessionId: String
    let openingMessage: String
    let setupSummary: String
    let voiceProfile: OpponentVoiceProfile
    @State private var messages: [PracticeMessageDTO] = []
    @State private var composedMessage = ""
    @State private var liveTranscript = ""
    @State private var isSending = false
    @State private var sendError: String?
    @State private var didSpeakOpening = false
    @State private var isPaused = false
    @State private var pulseListening = false
    @State private var silenceSendTask: Task<Void, Never>?

    private let silenceSendDelayNs: UInt64 = 2_500_000_000

    private var lastOpponentUtterance: String? {
        if let last = messages.last(where: { $0.role != "user" }) {
            return last.content
        }
        return openingMessage.isEmpty ? nil : openingMessage
    }

    private var displayDraft: String {
        speechRecognizer.isListening ? liveTranscript : composedMessage
    }

    private var statusText: String? {
        if isPaused, continuousMode { return "已暂停连续对话，点麦克风继续" }
        if isSending { return "正在等待对方回应…" }
        if speechSynthesizer.isSpeaking { return continuousMode ? "对方正在说话，点麦克风可打断" : "对方正在说话…" }
        if speechRecognizer.isListening {
            return continuousMode
                ? "可以说多段，停稳约 2.5 秒或点「说完了」再发送"
                : "松手后可继续说，点「说完了」再发送"
        }
        if !composedMessage.isEmpty { return "还可以补充，或点「说完了」发送" }
        if continuousMode, !isPaused { return "连续对话中，点麦克风开始说话" }
        return nil
    }

    var body: some View {
        VStack(spacing: 16) {
            if let sendError {
                Text(sendError)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            if let speechError = speechRecognizer.errorMessage {
                Text(speechError)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            if let statusText {
                Text(statusText)
                    .font(.footnote)
                    .foregroundStyle(.cyan)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(setupSummary).font(.caption).foregroundStyle(.secondary)
                            .padding().background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                        if messages.isEmpty, !openingMessage.isEmpty {
                            practiceBubble("AI：\(openingMessage)", isUser: false)
                                .id("opening")
                        }
                        ForEach(messages) { message in
                            practiceBubble(
                                message.role == "user" ? "我：\(message.content)" : "AI：\(message.content)",
                                isUser: message.role == "user"
                            )
                            .id(message.id)
                        }
                        if !displayDraft.isEmpty {
                            practiceBubble("我：\(displayDraft)", isUser: true)
                                .opacity(speechRecognizer.isListening ? 0.7 : 1)
                                .id("live-transcript")
                        }
                    }.padding()
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: displayDraft) { _, _ in
                    scrollToBottom(proxy)
                }
            }
            voiceControls
            NavigationLink("结束并生成复盘") {
                ReviewLoader(sessionId: sessionId)
            }
            .buttonStyle(.bordered)
            .padding(.bottom)
        }
        .background(AppBackground())
        .navigationTitle("语音练习")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    replayLastOpponent()
                } label: {
                    Image(systemName: "speaker.wave.2")
                }
                .disabled(lastOpponentUtterance == nil || speechSynthesizer.isSpeaking)
                .accessibilityLabel("重听对方")

                if continuousMode {
                    Button(isPaused ? "继续" : "暂停") {
                        togglePause()
                    }
                    .accessibilityIdentifier("practiceVoicePauseButton")
                }
            }
        }
        .task {
            speakOpeningIfNeeded()
        }
        .onChange(of: continuousMode) { _, enabled in
            if !enabled {
                isPaused = false
                speechRecognizer.stopListening()
            }
        }
        .onChange(of: speechRecognizer.isListening) { _, listening in
            pulseListening = listening && continuousMode
        }
        .onDisappear {
            cancelSilenceSend()
            speechRecognizer.stopListening()
            speechSynthesizer.stopSpeaking()
        }
    }

    private var voiceControls: some View {
        VStack(spacing: 10) {
            HStack {
                Toggle("连续对话", isOn: $continuousMode)
                    .font(.caption)
                Spacer()
                Picker("语速", selection: $speechRate) {
                    Text("慢").tag(0.85)
                    Text("正常").tag(0.95)
                    Text("快").tag(1.05)
                }
                .pickerStyle(.menu)
                .font(.caption)
            }
            .padding(.horizontal)

            Text(continuousMode ? "点麦克风说话，可分多段说完" : "按住说话，可分多段补充")
                .font(.caption)
                .foregroundStyle(.secondary)

            if canFinishComposing {
                Button("说完了") {
                    Task { await finishComposingAndSend() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(isSending)
                .accessibilityIdentifier("practiceVoiceFinishButton")
            }

            micButton
        }
        .padding(.bottom, 4)
    }

    private var canFinishComposing: Bool {
        !composedMessage.isEmpty || speechRecognizer.isListening
    }

    private var micButton: some View {
        let isActive = speechRecognizer.isListening
        let isDisabled = isSending || (speechSynthesizer.isSpeaking && !continuousMode)

        return Image(systemName: isActive ? "mic.fill" : "mic.circle.fill")
            .font(.system(size: 56))
            .foregroundStyle(isActive ? .red : (isPaused ? .gray : .cyan))
            .frame(width: 92, height: 92)
            .background((isActive ? Color.red : (isPaused ? Color.gray : Color.cyan)).opacity(0.15), in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(isActive ? Color.red : Color.cyan.opacity(isPaused ? 0.2 : 0.5), lineWidth: 2)
                    .scaleEffect(pulseListening ? 1.08 : 1)
                    .animation(
                        pulseListening ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default,
                        value: pulseListening
                    )
            }
            .opacity(isDisabled ? 0.45 : 1)
            .accessibilityIdentifier("practiceVoicePracticeButton")
            .accessibilityLabel(micAccessibilityLabel)
            .gesture(continuousMode ? nil : holdToSpeakGesture)
            .onTapGesture {
                guard continuousMode else { return }
                handleContinuousMicTap()
            }
    }

    private var micAccessibilityLabel: String {
        if continuousMode {
            if speechSynthesizer.isSpeaking { return "打断对方并说话" }
            if isPaused { return "继续连续对话" }
            if speechRecognizer.isListening { return "说完了并发送" }
            return "开始说话"
        }
        return speechRecognizer.isListening ? "松手发送" : "按住说话"
    }

    private var holdToSpeakGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isSending, !speechSynthesizer.isSpeaking, !speechRecognizer.isListening else { return }
                beginListening(resetComposed: composedMessage.isEmpty)
            }
            .onEnded { _ in
                speechRecognizer.endVoiceCapture()
            }
    }

    private func practiceBubble(_ text: String, isUser: Bool) -> some View {
        Text(text)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            .background(isUser ? Color.cyan.opacity(0.18) : Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }

    private func speakOpeningIfNeeded() {
        guard !didSpeakOpening, !openingMessage.isEmpty else { return }
        didSpeakOpening = true
        speechSynthesizer.speak(openingMessage, voiceProfile: voiceProfile, rateMultiplier: speechRate) {
            Task { await resumeContinuousIfNeeded() }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if !displayDraft.isEmpty {
                proxy.scrollTo("live-transcript", anchor: .bottom)
            } else if let last = messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            } else if !openingMessage.isEmpty {
                proxy.scrollTo("opening", anchor: .bottom)
            }
        }
    }

    private func replayLastOpponent() {
        guard let line = lastOpponentUtterance else { return }
        speechRecognizer.stopListening()
        speechSynthesizer.speak(line, voiceProfile: voiceProfile, rateMultiplier: speechRate)
    }

    private func togglePause() {
        if isPaused {
            isPaused = false
            Task { await beginAutoListening() }
        } else {
            isPaused = true
            cancelSilenceSend()
            speechRecognizer.stopListening()
            composedMessage = ""
            liveTranscript = ""
        }
    }

    private func handleContinuousMicTap() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking()
            isPaused = false
            Task { await beginAutoListening() }
            return
        }
        if speechRecognizer.isListening || !composedMessage.isEmpty {
            Task { await finishComposingAndSend() }
            return
        }
        if isPaused {
            isPaused = false
        }
        guard !isSending else { return }
        Task { await beginAutoListening() }
    }

    private func beginListening(resetComposed: Bool) {
        speechSynthesizer.stopSpeaking()
        cancelSilenceSend()
        if resetComposed {
            composedMessage = ""
        }
        liveTranscript = composedMessage
        sendError = nil
        Task {
            await speechRecognizer.startVoiceCompose(
                baseText: composedMessage,
                continueAfterSegmentFinal: continuousMode,
                onPartial: { partial in
                    liveTranscript = partial
                },
                onSegmentFinal: { segment in
                    appendSegment(segment)
                    if continuousMode {
                        scheduleSendAfterSilence()
                    }
                }
            )
        }
    }

    private func appendSegment(_ segment: String) {
        let trimmed = segment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        composedMessage = mergeVoiceText(composedMessage, trimmed)
        liveTranscript = composedMessage
    }

    private func mergeVoiceText(_ base: String, _ spoken: String) -> String {
        let trimmedBase = base.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSpoken = spoken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSpoken.isEmpty else { return base }
        if trimmedBase.isEmpty { return trimmedSpoken }
        if trimmedBase.hasSuffix(trimmedSpoken) { return trimmedBase }
        return "\(trimmedBase) \(trimmedSpoken)"
    }

    private func scheduleSendAfterSilence() {
        cancelSilenceSend()
        silenceSendTask = Task {
            try? await Task.sleep(nanoseconds: silenceSendDelayNs)
            guard !Task.isCancelled else { return }
            await finishComposingAndSend()
        }
    }

    private func cancelSilenceSend() {
        silenceSendTask?.cancel()
        silenceSendTask = nil
    }

    private func beginAutoListening() async {
        guard continuousMode, !isPaused, !isSending, !speechRecognizer.isListening, !speechSynthesizer.isSpeaking else { return }
        beginListening(resetComposed: true)
    }

    private func resumeContinuousIfNeeded() async {
        guard continuousMode, !isPaused else { return }
        await beginAutoListening()
    }

    private func finishComposingAndSend() async {
        cancelSilenceSend()
        if !liveTranscript.isEmpty {
            composedMessage = liveTranscript
        }
        speechRecognizer.stopListening()
        let outgoing = composedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        composedMessage = ""
        liveTranscript = ""
        guard !outgoing.isEmpty else { return }
        await sendVoiceMessage(outgoing)
    }

    private func sendVoiceMessage(_ content: String) async {
        let outgoing = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !outgoing.isEmpty else { return }

        isSending = true
        sendError = nil
        defer { isSending = false }

        do {
            let message = try await appState.api.sendPracticeMessage(sessionId: sessionId, content: outgoing)
            messages.append(.init(id: UUID().uuidString, role: "user", content: outgoing))
            messages.append(message)
            Feedback.tap()
            speechSynthesizer.speak(message.content, voiceProfile: voiceProfile, rateMultiplier: speechRate) {
                Task { await resumeContinuousIfNeeded() }
            }
        } catch {
            sendError = error.localizedDescription
        }
    }
}

struct ReviewLoader: View {
    @EnvironmentObject private var appState: AppState
    let sessionId: String
    @State private var review: ArgumentReview?
    @State private var error: String?
    @State private var loadToken = 0

    var body: some View {
        Group {
            if let review {
                ArgumentReviewView(review: review)
            } else if let error {
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        "复盘失败",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                    Button("重试") {
                        loadToken += 1
                        self.error = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                }
            } else {
                ProgressView("正在生成复盘...")
            }
        }
        .task(id: loadToken) {
            await loadReview()
        }
    }

    private func loadReview() async {
        do {
            let dto = try await appState.api.finishPractice(sessionId: sessionId)
            review = ArgumentReview(from: dto)
            await appState.refreshToyboxHome()
        } catch {
            self.error = error.localizedDescription
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
