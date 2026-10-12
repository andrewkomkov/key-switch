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
        let savedSelectionGestures = settings.selectionGestures, savedPlainPaste = settings.plainPaste
        settings.plainPaste = true
        let savedClipboardHistory = settings.clipboardHistory, savedClipboardLimit = settings.clipboardLimit
        settings.clipboardHistory = false
        let savedYofication = settings.yofication
        settings.yofication = false
        let savedFixCapitals = settings.fixCapitals
        settings.fixCapitals = false
        let savedSystemReplacements = settings.systemReplacements
        settings.systemReplacements = false
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
        settings.plainPaste = savedPlainPaste
        settings.yofication = savedYofication
        settings.fixCapitals = savedFixCapitals
        settings.systemReplacements = savedSystemReplacements
        (settings.clipboardHistory, settings.clipboardLimit) = (savedClipboardHistory, savedClipboardLimit)
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

        let bold = NSAttributedString(string: "bold", attributes: [.font: NSFont.boldSystemFont(ofSize: 40)])
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([bold])
        await start(in: english)
        await pasteCommand(shift: false)
        check("paste: Command-V keeps the format", pastedFontSize == 40, "text \(textView.string.debugDescription), size \(pastedFontSize)")
        await start(in: english)
        await pasteCommand(shift: true)
        check("paste: Command-Shift-V pastes the text only",
              textView.string == "bold" && pastedFontSize == 24,
              "text \(textView.string.debugDescription), size \(pastedFontSize)")
        check("paste: the clipboard keeps the formatted text",
              NSPasteboard.general.availableType(from: [.rtf]) != nil, "\(NSPasteboard.general.types ?? [])")

        settings.plainPaste = false
        await start(in: english)
        await pasteCommand(shift: true)
        expect("paste option off: the app gets the shortcut", text: "", layout: english)
        settings.plainPaste = true
        settings.excludedApps = [Bundle.main.bundleIdentifier ?? ""]
        await start(in: english)
        await pasteCommand(shift: true)
        expect("paste: an excluded app gets the shortcut", text: "", layout: english)
        settings.excludedApps = []

        let eshche = keys(for: "еще", in: russian), green = keys(for: "зеленый", in: russian)
        await start(in: russian)
        await type(eshche + [space])
        expect("yo option off: nothing changes", text: "еще ", layout: russian)

        settings.yofication = true
        settings.exceptions = []
        await start(in: russian)
        await type(eshche + [space] + keys(for: "все", in: russian) + [returnKey])
        expect("yo: еще gets the letter, все stays", text: "ещё все\n", layout: russian)
        await start(in: russian)
        await type(eshche, shift: true)
        await type([space])
        expect("yo: capitals stay capitals", text: "ЕЩЁ ", layout: russian)
        await start(in: russian)
        await type(eshche + [space])
        await doubleTapShift()
        expect("yo: double Shift brings the typed word back", text: "еще ", layout: russian)
        check("yo: the reverted word is an exception", settings.exceptions == ["еще"], "\(settings.exceptions)")
        await start(in: russian)
        await type(eshche + [space])
        expect("yo: an exception stays as typed", text: "еще ", layout: russian)
        settings.exceptions = []

        await start(in: english)
        await type(green + [space])
        expect("yo: a word from the incorrect layout gets the letter", text: "зелёный ", layout: russian)
        await doubleTapShift()
        expect("yo: double Shift undoes the conversion", text: "ptktysq ", layout: english)
        settings.exceptions = []
        settings.autoSwitch = false
        await start(in: english)
        await type(green)
        await doubleTapShift()
        expect("yo: a manual conversion gets the letter", text: "зелёный", layout: russian)
        settings.autoSwitch = true
        settings.yofication = false

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

        await capitalScenarios(english: english, russian: russian)
        await replacementScenarios(english: english)
        await clipboardScenarios(english: english, russian: russian)
    }

    /// Text replacements, with a list of the test in place of the list of macOS.
    private func replacementScenarios(english: Layout) async {
        Engine.shared.replacementsOverride = TextReplacements([("vbh", "very big hello"), ("ghbdtn", "shortcut")])
        settings.exceptions = []
        settings.autoSwitch = false
        await start(in: english)
        await type(mir + [space])
        expect("replacements option off: nothing changes", text: "vbh ", layout: english)

        settings.systemReplacements = true
        await start(in: english)
        await type(mir + [space])
        expect("replacements: a shortcut + Space", text: "very big hello ", layout: english)
        await doubleTapShift()
        expect("replacements: double Shift brings the shortcut back", text: "vbh ", layout: english)
        check("replacements: the reverted shortcut is an exception", settings.exceptions == ["vbh"], "\(settings.exceptions)")
        await start(in: english)
        await type(mir + [space])
        expect("replacements: an exception stays as typed", text: "vbh ", layout: english)
        settings.exceptions = []

        await start(in: english)
        await type([mir[0]], shift: true, settle: 0)
        await type(mir.dropFirst() + [returnKey])
        expect("replacements: a capital shortcut + Return", text: "Very big hello\n", layout: english)
        await start(in: english)
        await type(hello + [space] + mir + [43, space])  // 43: the comma key
        expect("replacements: a mark after the shortcut stays", text: "hello very big hello, ", layout: english)

        settings.autoSwitch = true
        await start(in: english)
        await type(privet + [space])
        expect("replacements: a shortcut wins over the detector", text: "shortcut ", layout: english)
        settings.excludedApps = [Bundle.main.bundleIdentifier ?? ""]
        await start(in: english)
        await type(mir + [space])
        expect("replacements: an excluded app keeps the shortcut", text: "vbh ", layout: english)
        settings.excludedApps = []
        settings.systemReplacements = false
        Engine.shared.replacementsOverride = nil
    }

    /// Accidental capitals in a finished word.
    private func capitalScenarios(english: Layout, russian: Layout) async {
        func typeHello(capitals: Range<Int>) async {
            for (index, key) in hello.enumerated() {
                await type([key], shift: capitals.contains(index), settle: 0)
            }
            await type([space])
        }
        settings.exceptions = []
        await start(in: english)
        await typeHello(capitals: 0..<2)
        expect("capitals option off: nothing changes", text: "HEllo ", layout: english)

        settings.fixCapitals = true
        await start(in: english)
        await typeHello(capitals: 0..<2)
        expect("capitals: HEllo + Space", text: "Hello ", layout: english)
        await doubleTapShift()
        expect("capitals: double Shift brings the typed word back", text: "HEllo ", layout: english)
        check("capitals: the reverted word is an exception", settings.exceptions == ["hello"], "\(settings.exceptions)")
        await start(in: english)
        await typeHello(capitals: 0..<2)
        expect("capitals: an exception stays as typed", text: "HEllo ", layout: english)
        settings.exceptions = []

        await start(in: english)
        await typeHello(capitals: 1..<5)
        expect("capitals: hELLO + Space", text: "Hello ", layout: english)
        await start(in: english)
        await typeHello(capitals: 0..<5)
        expect("capitals: a word in capitals stays", text: "HELLO ", layout: english)
        await start(in: english)
        await typeHello(capitals: 0..<1)
        expect("capitals: a correct word stays", text: "Hello ", layout: english)

        await start(in: english)
        await type(Array(privet.prefix(2)), shift: true, settle: 0)
        await type(privet.dropFirst(2) + [space])
        expect("capitals: a word from the incorrect layout gets one capital", text: "Привет ", layout: russian)
        await doubleTapShift()
        expect("capitals: double Shift undoes the conversion", text: "GHbdtn ", layout: english)
        settings.exceptions = []
        settings.fixCapitals = false
    }

    /// The clipboard history, in a temporary folder so that the real history stays as it is.
    private func clipboardScenarios(english: Layout, russian: Layout) async {
        let monitor = ClipboardMonitor.shared, pasteboard = NSPasteboard.general
        let folder = FileManager.default.temporaryDirectory.appending(path: "keyswitch-selftest-\(UUID().uuidString)")
        monitor.useDirectory(folder)
        settings.clipboardLimit = 25
        func copy(_ text: String, mark: String? = nil) async {
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            if let mark { pasteboard.setData(Data(), forType: .init(mark)) }
            await pause(0.8)
        }
        func names() -> [String] {
            monitor.history.entries.map { if case .text(let text) = $0.content { text } else { "image" } }
        }
        func checkHistory(_ name: String, _ expected: [String]) {
            check(name, names() == expected, "\(names()), expected \(expected)")
        }

        await copy("alpha")
        checkHistory("clipboard option off: the history stays empty", [])
        settings.clipboardHistory = true
        await copy("alpha")
        await copy("beta")
        checkHistory("clipboard: the newest entry is first", ["beta", "alpha"])
        await copy("alpha")
        checkHistory("clipboard: a second copy moves the entry to the top", ["alpha", "beta"])
        await copy("secret", mark: "org.nspasteboard.ConcealedType")
        checkHistory("clipboard: a concealed item is ignored", ["alpha", "beta"])

        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 4, pixelsHigh: 2, bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        pasteboard.clearContents()
        pasteboard.setData(bitmap?.representation(using: .png, properties: [:]), forType: .png)
        await pause(0.8)
        var imageFile = folder
        if case .image(let file, let width, let height, _)? = monitor.history.entries.first?.content {
            imageFile = folder.appending(path: file)
            check("clipboard: an image becomes an entry with a file",
                  width == 4 && height == 2 && FileManager.default.fileExists(atPath: imageFile.path),
                  "\(width) x \(height), \(file)")
        } else {
            fail("clipboard: an image becomes an entry with a file", "\(names())")
        }

        if let beta = monitor.history.entries.last {
            monitor.select(beta)
            await pause(0.8)
        }
        check("clipboard: a selected entry goes to the clipboard",
              pasteboard.string(forType: .string) == "beta", "\(pasteboard.string(forType: .string) ?? "nil")")
        checkHistory("clipboard: a selected entry goes to the top", ["beta", "image", "alpha"])
        if let image = monitor.history.entries.dropFirst().first {
            monitor.select(image)
            await pause(0.8)
        }
        check("clipboard: a selected image goes to the clipboard",
              pasteboard.data(forType: .png) != nil, "\(pasteboard.types ?? [])")
        checkHistory("clipboard: the image is on top", ["image", "beta", "alpha"])

        Engine.shared.selectionThroughClipboardOnly = true
        await start(in: english, text: "ghbdtn")
        await tap(shift, .maskShift, times: 2, settle: 1.5)
        expect("clipboard: the selection gesture still works", text: "привет", layout: russian)
        Engine.shared.selectionThroughClipboardOnly = false
        await copy("plain")
        await start(in: english)
        await pasteCommand(shift: true)
        await pause(0.6)
        expect("clipboard: the plain paste still works", text: "plain", layout: english)
        checkHistory("clipboard: the changes of the app stay out", ["plain", "image", "beta", "alpha"])

        let index = folder.appending(path: "history.json")
        let mode = (try? FileManager.default.attributesOfItem(atPath: index.path))?[.posixPermissions] as? Int
        check("clipboard: only the user can read the file", mode == 0o600, "mode \(mode.map { String($0, radix: 8) } ?? "nil")")
        monitor.useDirectory(folder)
        checkHistory("clipboard: the history stays after a restart", ["plain", "image", "beta", "alpha"])

        settings.clipboardLimit = 2
        await pause(0.8)
        checkHistory("clipboard: a smaller limit drops the oldest", ["plain", "image"])
        await copy("gamma")
        checkHistory("clipboard: a new entry drops the oldest", ["gamma", "plain"])
        check("clipboard: the file of a dropped image goes away",
              !FileManager.default.fileExists(atPath: imageFile.path), imageFile.lastPathComponent)

        func pinnedNames() -> [String] {
            monitor.history.pinned.map { if case .text(let text) = $0.content { text } else { "image" } }
        }
        if let plain = monitor.history.entries.last { monitor.togglePin(plain) }
        await copy("delta")
        await copy("epsilon")
        checkHistory("pin: the limit leaves a pinned entry alone", ["epsilon", "delta", "plain"])
        monitor.useDirectory(folder)
        check("pin: the pin stays after a restart", pinnedNames() == ["plain"], "\(pinnedNames())")
        await copy("plain")
        checkHistory("pin: a second copy moves the pinned entry to the top", ["plain", "epsilon", "delta"])
        check("pin: a second copy keeps the pin", pinnedNames() == ["plain"], "\(pinnedNames())")
        monitor.clear()
        checkHistory("pin: clear keeps the pinned entry", ["plain"])
        if let plain = monitor.history.entries.first { monitor.togglePin(plain) }
        check("pin: a second change removes the pin", pinnedNames() == [] && names() == ["plain"], "\(names())")

        settings.clipboardHistory = false
        await copy("delta")
        checkHistory("clipboard option off again: nothing is added", ["plain"])
        monitor.clear()
        checkHistory("clipboard: clear removes all entries", [])

        monitor.useDirectory(ClipboardMonitor.defaultDirectory)
        try? FileManager.default.removeItem(at: folder)
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
        textView.typingAttributes = [.font: NSFont.systemFont(ofSize: 24)]
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

    private func type(_ keys: [CGKeyCode], shift: Bool = false, settle: Double = 0.4) async {
        for key in keys {
            post(key, down: true, flags: shift ? .maskShift : [])
            post(key, down: false, flags: shift ? .maskShift : [])
            await pause(0.03)
        }
        await pause(settle)
    }

    private func pasteCommand(shift: Bool) async {
        let flags: CGEventFlags = shift ? [.maskCommand, .maskShift] : .maskCommand
        post(9, down: true, flags: flags)
        post(9, down: false, flags: flags)
        await pause(0.8)
    }

    /// Point size of the first character in the text view. 0 if the view is empty.
    private var pastedFontSize: CGFloat {
        guard let storage = textView.textStorage, storage.length > 0 else { return 0 }
        return (storage.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)?.pointSize ?? 0
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
