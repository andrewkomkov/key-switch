import SwiftUI

struct MenuView: View {
    @Bindable var settings: Settings
    let engine: Engine
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
