import SwiftUI

@main
struct KeySwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var settings = Settings.shared
    @State private var engine = Engine.shared

    var body: some Scene {
        MenuBarExtra {
            MenuView(settings: settings, engine: engine, showOnboarding: delegate.showOnboarding)
        } label: {
            Image(systemName: settings.isEnabled && engine.isTrusted ? "shift.fill" : "shift")
        }

        SwiftUI.Settings {
            SettingsView(settings: settings, engine: engine)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var onboarding: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Engine.shared.start()
        if let index = CommandLine.arguments.firstIndex(of: "--self-test") {
            let report = CommandLine.arguments.dropFirst(index + 1).first
            Task { await SelfTest(reportPath: report).run() }
        } else if !Engine.shared.isTrusted {
            showOnboarding()
        }
    }

    func showOnboarding() {
        if onboarding == nil {
            let window = NSWindow(contentViewController: NSHostingController(
                rootView: OnboardingView(engine: .shared) { [weak self] in self?.onboarding?.close() }))
            window.styleMask = [.titled, .closable, .fullSizeContentView]
            window.title = "KeySwitch"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.center()
            onboarding = window
        }
        NSApp.activate()
        onboarding?.makeKeyAndOrderFront(nil)
    }
}
