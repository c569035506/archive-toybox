import CoreGraphics
import Foundation

enum WoodFishRhythm {
    static let autoKnockIntervalMsDefault = 1000
    static let autoIntervalMinMs = 350
    static let autoIntervalMaxMs = 2500
    static let autoIntervalStepMs = 50
    static let comboWindowMs = 480
    static let maxMeritCombo = 999
    static let minManualGapMs = 48
    static let bounceMs = 300

    struct AutoIntervalPreset: Hashable {
        let intervalMs: Int
        let label: String
    }

    static let autoIntervalPresets: [AutoIntervalPreset] = [
        .init(intervalMs: 2500, label: "很慢"),
        .init(intervalMs: 1500, label: "慢"),
        .init(intervalMs: 1000, label: "标准"),
        .init(intervalMs: 600, label: "快"),
        .init(intervalMs: 350, label: "很快"),
    ]

    static func snapAutoIntervalMs(_ ms: Int) -> Int {
        autoIntervalPresets.min {
            abs($0.intervalMs - ms) < abs($1.intervalMs - ms)
        }?.intervalMs ?? autoKnockIntervalMsDefault
    }
}

enum KnockMode: String {
    case manual
    case auto
}

enum KnockPhase {
    case idle
    case hit
    case bounce
}

struct MeritFloatItem: Identifiable {
    let id = UUID()
    let merit: Int
    let offsetX: CGFloat
    let offsetY: CGFloat
    let risePx: CGFloat
}
