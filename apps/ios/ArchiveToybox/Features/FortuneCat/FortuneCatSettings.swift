import Foundation

enum FortuneCatSettings {
    private static let speedKey = "archive_toybox_fortune_cat_speed"

    static func loadSpeed() -> Double {
        let stored = UserDefaults.standard.double(forKey: speedKey)
        if stored == 0 { return FortuneCatRhythm.speedDefault }
        return FortuneCatRhythm.clampSpeed(stored)
    }

    static func saveSpeed(_ speed: Double) -> Double {
        let clamped = FortuneCatRhythm.clampSpeed(speed)
        UserDefaults.standard.set(clamped, forKey: speedKey)
        return clamped
    }

    static func formatSpeedLabel(_ speed: Double) -> String {
        String(format: "%.1f×", FortuneCatRhythm.clampSpeed(speed))
    }

    static func formatIntervalLabel(speed: Double) -> String {
        let ms = FortuneCatRhythm.intervalMs(forSpeed: speed)
        if ms >= 1000 {
            let seconds = Double(ms) / 1000.0
            if seconds.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0f 秒/次", seconds)
            }
            return String(format: "%.1f 秒/次", seconds)
        }
        return "\(ms) 毫秒/次"
    }
}
