import AppKit

/// The menu bar icon: a key with one Latin and one Cyrillic letter.
@MainActor
enum MenuBarIcon {
    static let active = image(filled: true)
    static let inactive = image(filled: false)

    /// A template image, so macOS sets the colour for a light and a dark menu bar.
    private static func image(filled: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 22, height: 16), flipped: false) { rect in
            let key = NSBezierPath(roundedRect: rect.insetBy(dx: 0.75, dy: 0.75), xRadius: 4, yRadius: 4)
            let letters = NSAttributedString(string: "Aя", attributes: [.font: font, .foregroundColor: NSColor.black])
            let size = letters.size()
            let origin = NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2)
            if filled {
                NSColor.black.setFill()
                key.fill()
                // The letters are holes in the key.
                NSGraphicsContext.current?.compositingOperation = .destinationOut
            } else {
                NSColor.black.setStroke()
                key.lineWidth = 1.25
                key.stroke()
            }
            letters.draw(at: origin)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "KeySwitch"
        return image
    }

    private static var font: NSFont {
        let base = NSFont.systemFont(ofSize: 10.5, weight: .bold)
        return base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: 10.5) } ?? base
    }
}
