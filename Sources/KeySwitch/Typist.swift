import CoreGraphics

/// Posts synthetic key events. Each event carries a mark, so that the event tap can tell
/// them from the keys of the user.
enum Typist {
    static let mark: Int64 = 0x4B53_5743  // "KSWC"

    private static let source = CGEventSource(stateID: .privateState)

    static func isOwn(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == mark
    }

    static func press(_ keyCode: CGKeyCode, flags: CGEventFlags = [], times: Int = 1) {
        for _ in 0..<times {
            post(keyCode, down: true, flags: flags)
            post(keyCode, down: false, flags: flags)
        }
    }

    /// Types the text without regard to the active layout.
    static func type(_ text: String) {
        for character in text {
            let units = Array(String(character).utf16)
            post(0, down: true, flags: [], text: units)
            post(0, down: false, flags: [], text: units)
        }
    }

    private static func post(_ keyCode: CGKeyCode, down: Bool, flags: CGEventFlags, text: [UniChar]? = nil) {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down) else { return }
        event.flags = flags
        if let text {
            event.keyboardSetUnicodeString(stringLength: text.count, unicodeString: text)
        }
        event.setIntegerValueField(.eventSourceUserData, value: mark)
        event.post(tap: .cgSessionEventTap)
    }
}
