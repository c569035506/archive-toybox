import Foundation

enum DabeiMantra {
    static let floatIntervalMs = 200
    static let meritIntervalMs = 340
    static let stageFloatIntervalMs = 580
    static let stageMaxFloats = 14
    static let floatFadeMs = 1_500

    static let labels = [
        "快乐 +1",
        "烦恼 -1",
        "好运 +1",
        "开心 +1",
        "霉运 -1",
        "福运 +1",
        "智慧 +1",
        "平安 +1",
        "顺心 +1",
        "焦虑 -1",
        "福气 +1",
        "晦气 -1",
        "喜悦 +1",
        "忧愁 -1",
        "财运 +1",
    ]

    static func pickLabel() -> String {
        labels.randomElement() ?? "福运 +1"
    }

    static func moodDelta(for label: String) -> (key: String, delta: Int)? {
        if label.contains("+1") {
            let key = label.replacingOccurrences(of: " +1", with: "")
            return (moodKey(for: key), 1)
        }
        if label.contains("-1") {
            let key = label.replacingOccurrences(of: " -1", with: "")
            return (moodKey(for: key), -1)
        }
        return nil
    }

    static func formatListenDuration(_ totalSec: Int) -> String {
        let sec = max(0, totalSec)
        if sec == 0 { return "0 秒" }
        if sec < 60 { return "\(sec) 秒" }
        let min = sec / 60
        let rest = sec % 60
        if rest == 0 { return "\(min) 分钟" }
        return "\(min) 分 \(rest) 秒"
    }

    private static func moodKey(for text: String) -> String {
        switch text {
        case "快乐", "开心", "喜悦": return "happy"
        case "烦恼", "焦虑", "忧愁", "晦气", "霉运": return "anxiety"
        case "好运", "福运", "福气", "财运": return "fortune"
        case "智慧": return "wisdom"
        case "平安", "顺心": return "calm"
        default: return "calm"
        }
    }
}

struct DabeiFloatItem: Identifiable {
    let id = UUID()
    let label: String
    let offsetX: CGFloat
    let offsetY: CGFloat
    let risePx: CGFloat
}
