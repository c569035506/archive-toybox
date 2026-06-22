import Foundation

enum DabeiSettings {
    private static let danmakuKey = "archive_toybox_dabei_danmaku"

    static func loadDanmakuEnabled() -> Bool {
        if UserDefaults.standard.object(forKey: danmakuKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: danmakuKey)
    }

    static func saveDanmakuEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: danmakuKey)
    }
}
