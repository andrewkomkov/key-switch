import Carbon
import KeySwitchCore

/// A keyboard layout enabled in System Settings.
struct Layout: Equatable {
    let source: TISInputSource
    let id: String
    let name: String
    /// Primary language code, for example `ru`.
    let language: String

    static func == (lhs: Layout, rhs: Layout) -> Bool { lhs.id == rhs.id }

    /// The text that the keys produce in this layout.
    func text(for keys: [Keystroke]) -> String {
        guard let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return ""
        }
        let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue() as Data
        return data.withUnsafeBytes { bytes -> String in
            let keyboard = bytes.bindMemory(to: UCKeyboardLayout.self).baseAddress!
            var result = ""
            var chars = [UniChar](repeating: 0, count: 4)
            for key in keys {
                var modifiers: UInt32 = 0
                if key.shift { modifiers |= UInt32(shiftKey >> 8) }
                if key.capsLock { modifiers |= UInt32(alphaLock >> 8) }
                var deadKeys: UInt32 = 0
                var length = 0
                let status = UCKeyTranslate(
                    keyboard, key.keyCode, UInt16(kUCKeyActionDown), modifiers,
                    UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysMask),
                    &deadKeys, chars.count, &length, &chars)
                if status == noErr, length > 0 {
                    result += String(utf16CodeUnits: chars, count: length)
                }
            }
            return result
        }
    }
}

enum InputSources {
    /// The enabled keyboard layouts, in the order of the input menu.
    static func layouts() -> [Layout] {
        let filter = [
            kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource!,
            kTISPropertyInputSourceIsSelectCapable: true,
        ] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        return list.compactMap(Layout.init)
    }

    static func current() -> Layout? {
        Layout(TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue())
    }

    static func select(_ layout: Layout) {
        TISSelectInputSource(layout.source)
    }
}

private extension Layout {
    init?(_ source: TISInputSource) {
        func property<T>(_ key: CFString) -> T? {
            guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
            return Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue() as? T
        }
        guard let type: String = property(kTISPropertyInputSourceType),
              type == kTISTypeKeyboardLayout as String,
              let id: String = property(kTISPropertyInputSourceID)
        else { return nil }
        let languages: [String] = property(kTISPropertyInputSourceLanguages) ?? []
        self.source = source
        self.id = id
        self.name = property(kTISPropertyLocalizedName) ?? id
        self.language = languages.first.map { String($0.prefix(2)) } ?? ""
    }
}
