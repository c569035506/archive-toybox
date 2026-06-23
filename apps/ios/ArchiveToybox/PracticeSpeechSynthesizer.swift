import AVFoundation

@MainActor
final class PracticeSpeechSynthesizer: NSObject, ObservableObject {
    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private var finishHandler: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(
        _ text: String,
        voiceProfile: OpponentVoiceProfile = .default,
        rateMultiplier: Double = 0.95,
        onFinish: (() -> Void)? = nil,
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onFinish?()
            return
        }

        stopSpeaking()
        finishHandler = onFinish

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let utterance = AVSpeechUtterance(string: trimmed)
        voiceProfile.configure(utterance, rateMultiplier: rateMultiplier)
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        guard isSpeaking || synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        finishHandler = nil
    }
}

extension PracticeSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            finishHandler?()
            finishHandler = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            finishHandler = nil
        }
    }
}
