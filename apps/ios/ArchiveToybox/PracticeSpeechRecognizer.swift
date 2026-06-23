import AVFoundation
import Speech

enum PracticeSpeechError: LocalizedError {
    case notAuthorized
    case recognizerUnavailable
    case audioSessionFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            "需要麦克风和语音识别权限才能使用语音输入。"
        case .recognizerUnavailable:
            "当前设备暂不支持中文语音识别。"
        case .audioSessionFailed:
            "无法启动麦克风，请稍后再试。"
        }
    }
}

@MainActor
final class PracticeSpeechRecognizer: ObservableObject {
    @Published private(set) var isListening = false
    @Published var errorMessage: String?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var baseDraft = ""
    private var continueAfterSegmentFinal = false
    private var onPartialUpdate: ((String) -> Void)?
    private var onSegmentFinal: ((String) -> Void)?

    deinit {
        recognitionTask?.cancel()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }

    func toggleListening(currentDraft: String, onUpdate: @escaping (String) -> Void) async {
        if isListening {
            stopListening()
            return
        }

        errorMessage = nil
        do {
            try await ensureAuthorization()
            try startCapture(
                baseText: currentDraft,
                continueAfterSegmentFinal: false,
                onPartial: onUpdate,
                onSegmentFinal: nil,
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func startVoiceCompose(
        baseText: String,
        continueAfterSegmentFinal: Bool,
        onPartial: @escaping (String) -> Void,
        onSegmentFinal: @escaping (String) -> Void,
    ) async {
        errorMessage = nil
        do {
            try await ensureAuthorization()
            try startCapture(
                baseText: baseText,
                continueAfterSegmentFinal: continueAfterSegmentFinal,
                onPartial: onPartial,
                onSegmentFinal: onSegmentFinal,
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func stopListening() {
        cancelListening()
    }

    func endVoiceCapture() {
        guard isListening else { return }
        recognitionRequest?.endAudio()
    }

    private func cancelListening() {
        guard isListening else { return }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        onPartialUpdate = nil
        onSegmentFinal = nil
        continueAfterSegmentFinal = false
        teardownAudioEngine()
        isListening = false
    }

    private func teardownAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    private func ensureAuthorization() async throws {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            throw PracticeSpeechError.notAuthorized
        }

        let micGranted = await AVAudioApplication.requestRecordPermission()
        guard micGranted else {
            throw PracticeSpeechError.notAuthorized
        }
    }

    private func startCapture(
        baseText: String,
        continueAfterSegmentFinal: Bool,
        onPartial: @escaping (String) -> Void,
        onSegmentFinal: ((String) -> Void)?,
    ) throws {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw PracticeSpeechError.recognizerUnavailable
        }

        cancelListening()
        baseDraft = baseText
        self.continueAfterSegmentFinal = continueAfterSegmentFinal
        onPartialUpdate = onPartial
        self.onSegmentFinal = onSegmentFinal

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        try beginRecognitionTask(with: speechRecognizer)

        if !audioEngine.isRunning {
            audioEngine.prepare()
            try audioEngine.start()
        }
        isListening = true
    }

    private func beginRecognitionTask(with speechRecognizer: SFSpeechRecognizer) throws {
        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if #available(iOS 13.0, *) {
            request.requiresOnDeviceRecognition = speechRecognizer.supportsOnDeviceRecognition
        }
        recognitionRequest = request

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let spoken = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                let merged = self.onSegmentFinal == nil
                    ? self.mergeDraft(base: self.baseDraft, spoken: spoken)
                    : self.mergeDraft(base: self.baseDraft, spoken: spoken)
                Task { @MainActor in
                    self.onPartialUpdate?(merged)
                }
            }

            if error != nil || result?.isFinal == true {
                Task { @MainActor in
                    await self.handleSegmentFinished(
                        speechRecognizer: speechRecognizer,
                        segment: result?.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                        failed: error != nil,
                    )
                }
            }
        }
    }

    private func handleSegmentFinished(
        speechRecognizer: SFSpeechRecognizer,
        segment: String,
        failed: Bool,
    ) async {
        let trimmedSegment = segment.trimmingCharacters(in: .whitespacesAndNewlines)
        if let onSegmentFinal {
            onSegmentFinal(trimmedSegment)
        }

        if continueAfterSegmentFinal, !failed {
            baseDraft = mergeDraft(base: baseDraft, spoken: trimmedSegment)
            do {
                try beginRecognitionTask(with: speechRecognizer)
                onPartialUpdate?(baseDraft)
                return
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }

        finishListening()
    }

    private func finishListening() {
        recognitionTask = nil
        recognitionRequest = nil
        onPartialUpdate = nil
        onSegmentFinal = nil
        continueAfterSegmentFinal = false
        teardownAudioEngine()
        isListening = false
    }

    private func mergeDraft(base: String, spoken: String) -> String {
        let trimmedBase = base.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSpoken = spoken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSpoken.isEmpty else { return base }
        if trimmedBase.isEmpty { return trimmedSpoken }
        if trimmedBase.hasSuffix(trimmedSpoken) { return trimmedBase }
        return "\(trimmedBase) \(trimmedSpoken)"
    }
}
