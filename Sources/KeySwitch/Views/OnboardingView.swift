import SwiftUI

/// Explains the Accessibility permission and waits until the user grants it.
struct OnboardingView: View {
    let engine: Engine
    let close: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text("Welcome to KeySwitch")
                .font(.largeTitle.bold())
            Text("KeySwitch needs the Accessibility permission to see Shift taps and to retype a word in the other layout.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Label("Tap Shift to switch the layout", systemImage: "shift")
                Label("Double-tap Shift to retype the last word", systemImage: "arrow.left.arrow.right")
                Label("Words typed in the wrong layout fix themselves", systemImage: "wand.and.sparkles")
                Label("Your keystrokes never leave this Mac and are never saved", systemImage: "lock.shield")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 12))

            if engine.isTrusted {
                Label("Access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
                Button("Start Typing", action: close)
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
            } else {
                Button("Open System Settings") {
                    engine.requestTrust()
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                Text("Turn on KeySwitch in Privacy & Security → Accessibility. This window updates by itself.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(width: 460)
        .animation(.default, value: engine.isTrusted)
    }
}
