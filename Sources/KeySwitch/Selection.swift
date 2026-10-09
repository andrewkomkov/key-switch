import AppKit
import ApplicationServices

/// Reads and replaces the selected text of the front app.
@MainActor
enum Selection {
    enum Reading {
        case text(String)
        /// A text field says that nothing is selected.
        case empty
        /// The app does not tell. Only a copy can find out.
        case unknown
    }

    static let maxLength = 5000

    static func read() -> Reading {
        var focused: CFTypeRef?
        let system = AXUIElementCreateSystemWide()
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let focused, CFGetTypeID(focused) == AXUIElementGetTypeID()
        else { return .unknown }
        let element = focused as! AXUIElement

        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &value) == .success,
           let text = value as? String, !text.isEmpty {
            return .text(text)
        }
        var role: CFTypeRef?, range: CFTypeRef?
        let textRoles = [kAXTextFieldRole, kAXTextAreaRole, kAXComboBoxRole]
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success,
              let role = role as? String, textRoles.contains(role),
              AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &range) == .success,
              let range, CFGetTypeID(range) == AXValueGetTypeID()
        else { return .unknown }
        var selected = CFRange()
        AXValueGetValue(range as! AXValue, .cfRange, &selected)
        return selected.length == 0 ? .empty : .unknown
    }

    /// Copies the selection with Command-C. `nil` if the clipboard did not change.
    static func copy() async -> String? {
        let pasteboard = NSPasteboard.general
        let before = pasteboard.changeCount
        Typist.press(8, flags: .maskCommand)
        for _ in 0..<20 where pasteboard.changeCount == before {
            try? await Task.sleep(for: .milliseconds(25))
        }
        guard pasteboard.changeCount != before, let text = pasteboard.string(forType: .string) else { return nil }
        // An editor that copies the full line when nothing is selected.
        if text.hasSuffix("\n"), !text.dropLast().contains("\n") { return nil }
        return text
    }

    /// Replaces the selection with the text through Command-V.
    static func paste(_ text: String) async {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        // Tells clipboard managers not to keep this.
        pasteboard.setData(Data(), forType: .init("org.nspasteboard.TransientType"))
        Typist.press(9, flags: .maskCommand)
        try? await Task.sleep(for: .milliseconds(300))
    }

    static func snapshot() -> [[NSPasteboard.PasteboardType: Data]] {
        (NSPasteboard.general.pasteboardItems ?? []).map { item in
            Dictionary(uniqueKeysWithValues: item.types.compactMap { type in
                item.data(forType: type).map { (type, $0) }
            })
        }
    }

    static func restore(_ snapshot: [[NSPasteboard.PasteboardType: Data]]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(snapshot.map { contents in
            let item = NSPasteboardItem()
            for (type, data) in contents { item.setData(data, forType: type) }
            return item
        })
    }
}
