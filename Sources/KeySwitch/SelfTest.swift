import AppKit

/// End-to-end check of the real pipeline: posts hardware-level key events into a text view
/// of this app and compares what arrives there. Needs the Accessibility permission.
///
/// Run: `open -W KeySwitch.app --args --self-test /path/to/report.txt`
@MainActor
final class SelfTest {
    private let reportPath: String?
    private let settings = Settings.shared
    private var textView = NSTextView()
    private var window: NSWindow?
    private var lines: [String] = []
    private var failures = 0

    // ANSI key codes. The same keys type `ghbdtn` in English and `привет` in Russian.
    private let privet: [CGKeyCode] = [5, 4, 11, 2, 17, 45]
    private let hello: [CGKeyCode] = [4, 14, 37, 37, 31]
    private let space: CGKeyCode = 49
    private let returnKey: CGKeyCode = 36
    private let shift: CGKeyCode = 56

    init(reportPath: String?) {
        self.reportPath = reportPath
    }

    func run() async {
        let saved = (settings.isEnabled, settings.shiftSwitches, settings.doubleShiftConverts,
                     settings.autoSwitch, settings.playSound, settings.excludedApps, settings.exceptions)
        let savedLayout = InputSources.current()
        (settings.isEnabled, settings.shiftSwitches, settings.doubleShiftConverts) = (true, true, true)
        (settings.autoSwitch, settings.playSound, settings.excludedApps, settings.exceptions) = (true, false, [], [])

        await scenarios()

        (settings.isEnabled, settings.shiftSwitches, settings.doubleShiftConverts,
         settings.autoSwitch, settings.playSound, settings.excludedApps, settings.exceptions) = saved
        if let savedLayout { InputSources.select(savedLayout) }
        lines.append(failures == 0 ? "RESULT: PASS" : "RESULT: FAIL (\(failures))")
        let report = lines.joined(separator: "\n") + "\n"
        if let reportPath {
            try? report.write(toFile: reportPath, atomically: true, encoding: .utf8)
        }
        print(report)
        exit(failures == 0 ? 0 : 1)
    }

    private func scenarios() async {
        for _ in 0..<120 where !Engine.shared.isReady { await pause(0.5) }
        guard Engine.shared.isReady else {
            return fail("setup", "the engine is not ready: no Accessibility permission or no word lists")
        }
        let layouts = InputSources.layouts()
        guard let english = layouts.first(where: { $0.language == "en" }),
              let russian = layouts.first(where: { $0.language == "ru" })
        else { return fail("setup", "an English and a Russian layout must be enabled") }
        guard layouts.count == 2 else { return fail("setup", "the test needs exactly 2 layouts, found \(layouts.count)") }
        openWindow()

        await start(in: english)
        await type(privet + [space])
        expect("auto: ghbdtn + Space on English", text: "привет ", layout: russian)

        await start(in: russian)
        await type(hello + [space])
        expect("auto: руддщ + Space on Russian", text: "hello ", layout: english)

        await start(in: english)
        await type(hello + [space])
        expect("auto: a correct word stays", text: "hello ", layout: english)

        await start(in: english)
        await type(privet + [returnKey])
        expect("auto: ghbdtn + Return", text: "привет\n", layout: russian)

        await start(in: english)
        await type(hello + [space] + privet + [space] + hello + [space])
        expect("auto: a wrong word in a sentence", text: "hello привет hello ", layout: english)

        await start(in: english)
        await tapShift()
        expect("Shift tap switches", text: "", layout: russian)
        await pause(0.6)
        await tapShift()
        expect("Shift tap switches back", text: "", layout: english)

        await start(in: english)
        await type([5], shift: true)
        expect("Shift as a modifier does not switch", text: "G", layout: english)

        settings.autoSwitch = false
        await start(in: english)
        await type(privet)
        await doubleTapShift()
        expect("double Shift converts the word", text: "привет", layout: russian)
        await pause(0.6)
        await doubleTapShift()
        expect("double Shift converts it back", text: "ghbdtn", layout: english)

        await start(in: english)
        await type(hello + [space] + privet + [space, space])
        await doubleTapShift()
        expect("double Shift keeps the earlier text and the spaces", text: "hello привет  ", layout: russian)

        await start(in: english)
        await type(privet + [123])  // left arrow
        await doubleTapShift()
        expect("double Shift after a caret move changes only the layout", text: "ghbdtn", layout: russian)

        await start(in: english)
        await type(privet + [space])
        expect("auto-switch off: nothing changes", text: "ghbdtn ", layout: english)
        settings.autoSwitch = true

        await start(in: english)
        await type(privet + [space])
        await doubleTapShift()
        expect("double Shift undoes an automatic conversion", text: "ghbdtn ", layout: english)
        check("the undone word is an exception", settings.exceptions == ["ghbdtn"], "\(settings.exceptions)")
        await start(in: english)
        await type(privet + [space])
        expect("an exception is not converted again", text: "ghbdtn ", layout: english)
    }

    // MARK: - Driving

    private func openWindow() {
        textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 420, height: 160))
        textView.font = .systemFont(ofSize: 24)
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        let window = NSWindow(
            contentRect: textView.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.title = "KeySwitch self-test"
        window.contentView = textView
        window.center()
        window.level = .floating
        self.window = window
    }

    private func start(in layout: Layout) async {
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(textView)
        // Escape resets the word buffer and the Shift recognizer of the engine.
        await type([53])
        textView.string = ""
        InputSources.select(layout)
        await pause(0.6)
    }

    private func type(_ keys: [CGKeyCode], shift: Bool = false) async {
        for key in keys {
            post(key, down: true, flags: shift ? .maskShift : [])
            post(key, down: false, flags: shift ? .maskShift : [])
            await pause(0.03)
        }
        await pause(0.4)
    }

    private func tapShift() async {
        post(shift, down: true, flags: .maskShift)
        await pause(0.05)
        post(shift, down: false, flags: [])
        await pause(0.1)
    }

    private func doubleTapShift() async {
        await tapShift()
        await tapShift()
        await pause(0.4)
    }

    private func post(_ key: CGKeyCode, down: Bool, flags: CGEventFlags) {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: down)
        event?.flags = flags
        event?.post(tap: .cghidEventTap)
    }

    private func pause(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    // MARK: - Checking

    private func expect(_ name: String, text: String, layout: Layout) {
        let actualLayout = InputSources.current()
        check(name, textView.string == text && actualLayout == layout,
              "text \(textView.string.debugDescription), layout \(actualLayout?.language ?? "?"); "
              + "expected \(text.debugDescription), \(layout.language)")
    }

    private func check(_ name: String, _ passed: Bool, _ detail: String) {
        if passed {
            lines.append("PASS  \(name)")
        } else {
            fail(name, detail)
        }
    }

    private func fail(_ name: String, _ detail: String) {
        failures += 1
        lines.append("FAIL  \(name): \(detail)")
    }
}
