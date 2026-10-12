import Foundation
import KeySwitchCore

/// The list of System Settings, Keyboard, Text Replacements. macOS keeps it in the global
/// preferences and tells no other app about a change, so the list is read again after a while.
@MainActor
enum SystemReplacements {
    private static let key = "NSUserDictionaryReplacementItems"
    private static let maxAge: TimeInterval = 5
    private static var cached = TextReplacements([])
    private static var readAt = -Double.infinity

    static var current: TextReplacements {
        let now = ProcessInfo.processInfo.systemUptime
        if now - readAt > maxAge {
            cached = read()
            readAt = now
        }
        return cached
    }

    private static func read() -> TextReplacements {
        let items = UserDefaults.standard.array(forKey: key) as? [[String: Any]] ?? []
        return TextReplacements(items.compactMap { item in
            guard (item["on"] as? Bool) != false,
                  let shortcut = item["replace"] as? String, let phrase = item["with"] as? String
            else { return nil }
            return (shortcut, phrase)
        })
    }
}
