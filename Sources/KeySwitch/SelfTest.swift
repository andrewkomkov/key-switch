import AppKit
import KeySwitchCore

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
    /// The test window lost the keyboard focus. No more keys are posted after that.
    private var lostFocus = false

    // ANSI key codes. The same keys type `ghbdtn` in English and `привет` in Russian.
    private let privet: [CGKeyCode] = [5, 4, 11, 2, 17, 45]
    private let hello: [CGKeyCode] = [4, 14, 37, 37, 31]
    // `recieve` in English.
    private let recieve: [CGKeyCode] = [15, 14, 8, 34, 14, 9, 14]
    // `севодня` in Russian.
    private let sevodnya: [CGKeyCode] = [8, 17, 2, 38, 37, 16, 6]
    private let space: CGKeyCode = 49
    private let returnKey: CGKeyCode = 36
    private let shift: CGKeyCode = 56
    private let option: CGKeyCode = 58
    // `vbh` in English, `мир` in Russian.
    private let mir: [CGKeyCode] = [9, 11, 4]

    init(reportPath: String?) {
        self.reportPath = reportPath
    }

    func run() async {
        let saved = (settings.isEnabled, settings.shiftSwitches, settings.doubleShiftConverts,
                     settings.autoSwitch, settings.playSound, settings.excludedApps, settings.exceptions)
        let savedFixTypos = settings.fixTypos, savedCaseGesture = settings.caseGesture
        let savedSelectionGestures = settings.selectionGestures
        let savedLearnWords = settings.learnWords, savedLearnedWords = settings.learnedWords
        settings.learnWords = false
        settings.learnedWords = []
        let savedClipboard = Selection.snapshot()
        settings.selectionGestures = true
        settings.fixTypos = false
        settings.caseGesture = true
        let savedLayout = InputSources.current()
        (settings.isEnabled, settings.shiftSwitches, settings.doubleShiftConverts) = (true, true, true)
        (settings.autoSwitch, settings.playSound, settings.excludedApps, settings.exceptions) = (true, false, [], [])

        await scenarios()

        (settings.isEnabled, settings.shiftSwitches, settings.doubleShiftConverts,
         settings.autoSwitch, settings.playSound, settings.excludedApps, settings.exceptions) = saved
        settings.fixTypos = savedFixTypos
        settings.caseGesture = savedCaseGesture
        settings.selectionGestures = savedSelectionGestures
        settings.learnWords = savedLearnWords
        settings.learnedWords = savedLearnedWords
        Selection.restore(savedClipboard)
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
        await type(hello + [space] + privet + [space])
        await doubleTapShift()
        expect("double Shift keeps the earlier text and the space", text: "hello привет ", layout: russian)

        await start(in: english)
        await type(privet + [123])  // left arrow
        await doubleTapShift()
        expect("double Shift after a caret move changes only the layout", text: "ghbdtn", layout: russian)

        await start(in: english)
        await type(privet + [space])
        expect("auto-switch off: nothing changes", text: "ghbdtn ", layout: english)
        settings.autoSwitch = true

        settings.excludedApps = [Bundle.main.bundleIdentifier ?? ""]
        await start(in: english)
        await type(privet + [space])
        expect("excluded app: nothing changes", text: "ghbdtn ", layout: english)
        settings.excludedApps = []

        await start(in: english)
        await type(privet + [space])
        await doubleTapShift()
        expect("double Shift undoes an automatic conversion", text: "ghbdtn ", layout: english)
        check("the undone word is an exception", settings.exceptions == ["ghbdtn"], "\(settings.exceptions)")
        await start(in: english)
        await type(privet + [space])
        expect("an exception is not converted again", text: "ghbdtn ", layout: english)
        settings.exceptions = []

        await start(in: english)
        await type(recieve + [space])
        expect("typo option off: nothing changes", text: "recieve ", layout: english)

        settings.fixTypos = true
        await start(in: english)
        await type(recieve + [space])
        expect("typo: recieve + Space in English", text: "receive ", layout: english)
        await doubleTapShift()
        expect("typo: double Shift brings the typed word back", text: "recieve ", layout: english)
        check("typo: the reverted word is an exception", settings.exceptions == ["recieve"], "\(settings.exceptions)")
        await start(in: english)
        await type(recieve + [space])
        expect("typo: an exception stays as typed", text: "recieve ", layout: english)

        await start(in: russian)
        await type(sevodnya + [space])
        expect("typo: севодня + Space in Russian", text: "сегодня ", layout: russian)

        await start(in: english)
        await type([7, 12, 6, 17, returnKey])
        expect("typo: a word with no sure correction stays", text: "xqzt\n", layout: english)

        await start(in: english)
        await type(hello + [space] + privet + [space])
        expect("typo option on: the layout correction still works", text: "hello привет ", layout: russian)

        settings.fixTypos = false
        settings.autoSwitch = false
        await start(in: english)
        await type(privet + [space] + mir + [space])
        await tap(shift, .maskShift, times: 3)
        expect("phrase: three Shift taps convert two words", text: "привет мир ", layout: russian)
        await pause(0.6)
        await tap(shift, .maskShift, times: 2)
        expect("phrase: double Shift converts both words back", text: "ghbdtn vbh ", layout: english)

        await start(in: english)
        await type(privet)
        await tap(shift, .maskShift, times: 4)
        expect("phrase: more taps than words change nothing more", text: "привет", layout: russian)

        await start(in: english)
        await type(hello)
        await tap(option, .maskAlternate, times: 2)
        expect("case: double Option capitalizes the word", text: "Hello", layout: english)
        await pause(0.6)
        await tap(option, .maskAlternate, times: 3)
        expect("case: each later tap goes on in the cycle", text: "hello", layout: english)

        await start(in: english)
        await type([4])
        await type([14, 37, 37, 31], shift: true)
        await tap(option, .maskAlternate, times: 2)
        expect("case: a Caps Lock mistake gets inverted", text: "Hello", layout: english)
        await pause(0.6)
        await tap(shift, .maskShift, times: 2)
        expect("case: a layout conversion keeps the new case", text: "Руддщ", layout: russian)

        settings.caseGesture = false
        await start(in: english)
        await type(hello)
        await tap(option, .maskAlternate, times: 2)
        expect("case option off: nothing changes", text: "hello", layout: english)
        settings.caseGesture = true
        settings.autoSwitch = true

        for throughClipboard in [false, true] {
            Engine.shared.selectionThroughClipboardOnly = throughClipboard
            let path = throughClipboard ? "clipboard" : "accessibility"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("sentinel", forType: .string)

            await start(in: english, text: "ghbdtn vbh\nntcn")
            await tap(shift, .maskShift, times: 2, settle: 1.2)
            expect("selection (\(path)): double Shift converts two lines", text: "привет мир\nтест", layout: russian)
            await tap(shift, .maskShift, times: 2, settle: 1.2)
            expect("selection (\(path)): a second gesture brings the text back", text: "ghbdtn vbh\nntcn", layout: english)
            check("selection (\(path)): the clipboard keeps its content",
                  NSPasteboard.general.string(forType: .string) == "sentinel",
                  "\(NSPasteboard.general.string(forType: .string) ?? "nil")")

            await start(in: russian, text: "руддщ")
            await tap(shift, .maskShift, times: 2, settle: 1.2)
            expect("selection (\(path)): Russian keys become English", text: "hello", layout: english)

            await start(in: english, text: "hello world")
            await tap(option, .maskAlternate, times: 2, settle: 1.2)
            expect("selection (\(path)): double Option changes the case", text: "Hello world", layout: english)
            await tap(option, .maskAlternate, times: 2, settle: 1.2)
            expect("selection (\(path)): a second gesture goes on in the cycle", text: "HELLO WORLD", layout: english)

            await start(in: english, text: "ghbdtn", select: false)
            await tap(shift, .maskShift, times: 2, settle: 1.2)
            expect("selection (\(path)): no selection, no change", text: "ghbdtn", layout: russian)
        }
        Engine.shared.selectionThroughClipboardOnly = false

        settings.selectionGestures = false
        await start(in: english, text: "ghbdtn")
        await tap(shift, .maskShift, times: 2, settle: 1.2)
        expect("selection option off: nothing changes", text: "ghbdtn", layout: russian)
        settings.selectionGestures = true

        let git = keys(for: "гит", in: russian), approve = keys(for: "апрув", in: russian)
        let gitThreeTimes = git + [space] + git + [space] + git + [space]
        await start(in: russian)
        await type(gitThreeTimes)
        check("learning off: the list stays empty", settings.learnedWords.isEmpty, "\(settings.learnedWords)")

        settings.learnWords = true
        await start(in: english)
        await type(git + [space])
        expect("learning: an unknown short word stays before it is learned", text: "ubn ", layout: english)
        await start(in: russian)
        await type(gitThreeTimes)
        expect("learning: three uses in the right layout stay as typed", text: "гит гит гит ", layout: russian)
        check("learning: the third use puts the word in the list", settings.learnedWords == ["ru:гит"], "\(settings.learnedWords)")
        await start(in: english)
        await type(git + [space])
        expect("learning: the learned word is converted from the other layout", text: "гит ", layout: russian)

        settings.learnedWords = []
        await start(in: english)
        await type(git + [space])
        expect("learning: a removed word is unknown again", text: "ubn ", layout: english)

        await start(in: english)
        await type(approve)
        await doubleTapShift()
        expect("learning: a manual conversion", text: "апрув", layout: russian)
        check("learning: the manual conversion puts the word in the list", settings.learnedWords == ["ru:апрув"], "\(settings.learnedWords)")
        await start(in: english)
        await type(approve + [space])
        expect("learning: the word is converted by itself from then on", text: "апрув ", layout: russian)

        await start(in: english)
        await type(approve)
        await doubleTapShift()
        await pause(0.6)
        await doubleTapShift()
        expect("learning: a conversion and a conversion back", text: "fghed", layout: english)
        check("learning: the conversion back teaches nothing", settings.learnedWords == [], "\(settings.learnedWords)")
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
        // An accessory app cannot reliably take the keyboard focus.
        NSApp.setActivationPolicy(.regular)
        // Command-C and Command-V reach the text view through the Edit menu.
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        let main = NSMenu()
        main.addItem(NSMenuItem())
        main.addItem(NSMenuItem())
        main.items[1].submenu = edit
        NSApp.mainMenu = main
    }

    private var hasFocus: Bool {
        NSApp.isActive && window?.isKeyWindow == true && window?.firstResponder === textView
    }

    /// - Parameter text: text to put in the view, fully selected unless `select` is false.
    private func start(in layout: Layout, text: String = "", select: Bool = true) async {
        guard !lostFocus else { return }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(textView)
        for _ in 0..<30 where !hasFocus { await pause(0.1) }
        lostFocus = !hasFocus
        Engine.shared.resetInputState()
        textView.string = text
        textView.setSelectedRange(NSRange(location: select ? 0 : (text as NSString).length,
                                          length: select ? (text as NSString).length : 0))
        InputSources.select(layout)
        await pause(0.6)
    }

    /// The keys that type the text in the layout, without Shift.
    private func keys(for text: String, in layout: Layout) -> [CGKeyCode] {
        text.compactMap { character in
            (CGKeyCode(0)..<52).first { layout.text(for: [Keystroke(keyCode: $0)]) == String(character) }
        }
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
        await tap(shift, .maskShift, times: 1, settle: 0.1)
    }

    private func doubleTapShift() async {
        await tap(shift, .maskShift, times: 2)
    }

    /// Taps a modifier key in one series.
    private func tap(_ key: CGKeyCode, _ flag: CGEventFlags, times: Int, settle: Double = 0.4) async {
        for index in 0..<times {
            if index > 0 { await pause(0.1) }
            post(key, down: true, flags: flag)
            await pause(0.05)
            post(key, down: false, flags: [])
        }
        await pause(settle)
    }

    private func post(_ key: CGKeyCode, down: Bool, flags: CGEventFlags) {
        // Never type into another app.
        guard !lostFocus, hasFocus else {
            lostFocus = true
            return
        }
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
        if lostFocus {
            fail(name, "the test window lost the keyboard focus")
        } else if passed {
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
