// Draws the app icon and writes Resources/AppIcon.icns.
// Usage: swift Scripts/make-icon.swift
import AppKit

func render(_ size: CGFloat) -> Data {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let inset = size * 0.1
    let rect = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let shape = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.225, yRadius: rect.width * 0.225)
    NSGradient(colors: [
        NSColor(red: 0.38, green: 0.36, blue: 0.98, alpha: 1),
        NSColor(red: 0.10, green: 0.62, blue: 0.98, alpha: 1),
    ])!.draw(in: shape, angle: -60)

    func draw(_ text: String, fontSize: CGFloat, weight: NSFont.Weight, at center: CGPoint, alpha: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size * fontSize, weight: weight),
            .foregroundColor: NSColor.white.withAlphaComponent(alpha),
        ]
        let bounds = (text as NSString).size(withAttributes: attributes)
        (text as NSString).draw(
            at: CGPoint(x: size * center.x - bounds.width / 2, y: size * center.y - bounds.height / 2),
            withAttributes: attributes)
    }
    draw("⇧", fontSize: 0.46, weight: .bold, at: CGPoint(x: 0.5, y: 0.56), alpha: 1)
    draw("A ⇄ Я", fontSize: 0.105, weight: .semibold, at: CGPoint(x: 0.5, y: 0.25), alpha: 0.9)
    NSGraphicsContext.current = nil
    return bitmap.representation(using: .png, properties: [:])!
}

let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        try render(CGFloat(points * scale)).write(to: iconset.appendingPathComponent(name))
    }
}
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try iconutil.run()
iconutil.waitUntilExit()
