import AVFoundation

enum OpponentVoiceGender: String, CaseIterable, Identifiable, Codable {
    case male
    case female

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: "男声"
        case .female: "女声"
        }
    }
}

enum OpponentVoiceAge: String, CaseIterable, Identifiable, Codable {
    case child
    case youth
    case middle
    case elderly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .child: "幼年"
        case .youth: "青年"
        case .middle: "中年"
        case .elderly: "老年"
        }
    }
}

struct OpponentVoiceProfile: Equatable, Codable {
    var gender: OpponentVoiceGender
    var age: OpponentVoiceAge

    static let `default` = OpponentVoiceProfile(gender: .female, age: .middle)

    var summary: String {
        "\(gender.title) · \(age.title)"
    }

    func configure(_ utterance: AVSpeechUtterance, rateMultiplier: Double) {
        utterance.voice = Self.resolveVoice(gender: gender)
        utterance.pitchMultiplier = Self.pitchMultiplier(gender: gender, age: age)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            * Float(rateMultiplier)
            * Self.ageRateMultiplier(age: age)
    }

    static func resolveVoice(gender: OpponentVoiceGender) -> AVSpeechSynthesisVoice? {
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language == "zh-CN" || $0.language.hasPrefix("zh-Hans")
        }

        let ranked = candidates.sorted { lhs, rhs in
            voiceScore(gender: gender, voice: lhs) > voiceScore(gender: gender, voice: rhs)
        }

        if let best = ranked.first, voiceScore(gender: gender, voice: best) > 0 {
            return best
        }

        return AVSpeechSynthesisVoice(language: "zh-CN")
    }

    private static func voiceScore(gender: OpponentVoiceGender, voice: AVSpeechSynthesisVoice) -> Int {
        let identifier = voice.identifier.lowercased()
        let name = voice.name.lowercased()

        switch gender {
        case .female:
            if identifier.contains("tingting") || name.contains("ting") { return 100 }
            if identifier.contains("meijia") || name.contains("mei") { return 90 }
            if voice.gender == .female { return 80 }
            return 10
        case .male:
            if identifier.contains("yunxi") || name.contains("yun") { return 100 }
            if identifier.contains("li-mu") || identifier.contains("limu") { return 95 }
            if voice.gender == .male { return 85 }
            if identifier.contains("male") { return 70 }
            return 10
        }
    }

    private static func pitchMultiplier(gender: OpponentVoiceGender, age: OpponentVoiceAge) -> Float {
        let agePitch: Float = switch age {
        case .child: 1.28
        case .youth: 1.08
        case .middle: 1.0
        case .elderly: 0.82
        }

        switch gender {
        case .male:
            return agePitch * 0.9
        case .female:
            return agePitch
        }
    }

    private static func ageRateMultiplier(age: OpponentVoiceAge) -> Float {
        switch age {
        case .child: 1.08
        case .youth: 1.02
        case .middle: 1.0
        case .elderly: 0.88
        }
    }
}

extension OpponentVoiceGender {
    init(apiValue: String) {
        self = OpponentVoiceGender(rawValue: apiValue) ?? .female
    }
}

extension OpponentVoiceAge {
    init(apiValue: String) {
        self = OpponentVoiceAge(rawValue: apiValue) ?? .middle
    }
}
