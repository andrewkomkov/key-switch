import KeySwitchCore
import SwiftUI

struct MenuView: View {
    @Bindable var settings: Settings
    let engine: Engine
    let clipboard: ClipboardMonitor
    let showOnboarding: () -> Void
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        if !engine.isTrusted {
            Button("Grant Accessibility Access…", systemImage: "exclamationmark.triangle", action: showOnboarding)
            Divider()
        }
        Toggle("Enabled", isOn: $settings.isEnabled)
        Toggle("Switch Layout Automatically", isOn: $settings.autoSwitch)
        if let app = engine.frontApp, let bundleID = app.bundleIdentifier {
            Toggle(
                "Never Auto-Switch in \(app.localizedName ?? bundleID)",
                isOn: Binding(
                    get: { settings.isExcluded(bundleID) },
                    set: { _ in settings.toggleExclusion(of: bundleID) }))
        }
        if settings.clipboardHistory {
            Divider()
            ClipboardMenu(clipboard: clipboard)
        }
        Divider()
        Button("Settings…") {
            NSApp.activate()
            openSettings()
        }
        .keyboardShortcut(",")
        Button("Quit KeySwitch") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}

/// The clipboard history: the pinned entries, the newest entries, then the others in a submenu.
private struct ClipboardMenu: View {
    let clipboard: ClipboardMonitor
    private static let visible = 15

    var body: some View {
        let pinned = clipboard.history.pinned, entries = clipboard.history.recent
        if !pinned.isEmpty {
            Section("Pinned") {
                ForEach(pinned) { entry in
                    ClipboardEntryLabel(entry: entry, clipboard: clipboard, asButton: true)
                }
            }
        }
        Section("Clipboard") {
            if entries.isEmpty {
                Text(pinned.isEmpty ? LocalizedStringKey("Nothing copied yet") : "No other entries")
            } else if pinned.isEmpty {
                Text("Option-click an entry to pin it")
            }
            ForEach(entries.prefix(Self.visible)) { entry in
                ClipboardEntryLabel(entry: entry, clipboard: clipboard, asButton: true)
            }
            if entries.count > Self.visible {
                Menu("Earlier") {
                    ForEach(entries.dropFirst(Self.visible)) { entry in
                        ClipboardEntryLabel(entry: entry, clipboard: clipboard, asButton: true)
                    }
                }
            }
            if !entries.isEmpty {
                Button("Clear History", systemImage: "trash", action: clipboard.clear)
            }
        }
    }
}

/// One entry: the start of the text, or a small picture with the size of the image.
struct ClipboardEntryLabel: View {
    let entry: ClipboardEntry
    let clipboard: ClipboardMonitor
    var asButton = false

    var body: some View {
        if asButton {
            Button {
                // A menu item has one action, so Option makes the second one.
                if NSEvent.modifierFlags.contains(.option) {
                    clipboard.togglePin(entry)
                } else {
                    clipboard.select(entry)
                }
            } label: { label }
        } else {
            label
        }
    }

    @ViewBuilder private var label: some View {
        switch entry.content {
        case .text(let text):
            Text(verbatim: ClipboardHistory.title(for: text))
        case .image(_, let width, let height, _):
            Label {
                Text("Image \(width) × \(height)")
            } icon: {
                if let thumbnail = clipboard.thumbnail(for: entry) {
                    Image(nsImage: thumbnail)
                } else {
                    Image(systemName: "photo")
                }
            }
        }
    }
}
