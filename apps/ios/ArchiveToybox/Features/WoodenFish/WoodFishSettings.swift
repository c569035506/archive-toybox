import Foundation

enum WoodFishSettings {
    private static let autoIntervalKey = "archive_toybox_woodfish_auto_interval_ms"

    static func loadAutoIntervalMs() -> Int {
        let stored = UserDefaults.standard.integer(forKey: autoIntervalKey)
        if stored == 0 { return WoodFishRhythm.autoKnockIntervalMsDefault }
        return WoodFishRhythm.snapAutoIntervalMs(stored)
    }

    static func saveAutoIntervalMs(_ ms: Int) -> Int {
        let snapped = WoodFishRhythm.snapAutoIntervalMs(ms)
        UserDefaults.standard.set(snapped, forKey: autoIntervalKey)
        return snapped
    }

    static func formatAutoIntervalLabel(_ ms: Int) -> String {
        if ms >= 1000 {
            let seconds = Double(ms) / 1000.0
            if seconds.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0f 秒/下", seconds)
            }
            return String(format: "%.1f 秒/下", seconds)
        }
        return "\(ms) 毫秒/下"
    }
}
