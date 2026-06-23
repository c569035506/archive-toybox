import CoreGraphics
import Foundation

enum FortuneCatRhythm {
    static let baseIntervalMs = 1200
    static let waveMs = 520
    static let speedMin = 0.6
    static let speedMax = 1.8
    static let speedDefault = 1.0
    static let speedStep = 0.1

    struct SpeedPreset: Hashable {
        let speed: Double
        let label: String
    }

    static let speedPresets: [SpeedPreset] = [
        .init(speed: 0.6, label: "慢"),
        .init(speed: 0.9, label: "较慢"),
        .init(speed: 1.0, label: "标准"),
        .init(speed: 1.4, label: "较快"),
        .init(speed: 1.8, label: "快"),
    ]

    static func intervalMs(forSpeed speed: Double) -> Int {
        let clamped = snapSpeed(speed)
        return Int((Double(baseIntervalMs) / clamped).rounded())
    }

    static func snapSpeed(_ speed: Double) -> Double {
        speedPresets.min {
            abs($0.speed - speed) < abs($1.speed - speed)
        }?.speed ?? speedDefault
    }

    static func clampSpeed(_ speed: Double) -> Double {
        snapSpeed(speed)
    }

    // "金币不断掉落"：每次财运 +1 同步掉落一枚硬币（动画时长与移除时长一致）
    static let coinDropDuration: Double = 1.1
    static let coinSpawnLifespanNs: UInt64 = 1_150_000_000
    static let floatFadeMs = 1_150
    static let coinStartOffsetY: CGFloat = -40
    static let coinEndOffsetY: CGFloat = 160
}

struct FortuneFloatItem: Identifiable {
    let id = UUID()
    let offsetX: CGFloat
    let offsetY: CGFloat
    let risePx: CGFloat
}

struct FortuneCoinItem: Identifiable {
    let id = UUID()
    let offsetX: CGFloat
    let startY: CGFloat
}
