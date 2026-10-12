import AppKit
import Carbon
import KeySwitchCore
import Observation
import os

/// Watches the keyboard through an event tap and reacts to Shift taps and finished words.
@MainActor
@Observable
final class Engine {
    static let shared = Engine()

    /// The app has the Accessibility permission.
    private(set) var isTrusted = AXIsProcessTrusted()
    /// The app that has the keyboard focus, other than KeySwitch.
    private(set) var frontApp: NSRunningApplication?
    /// Conversions since the app started.
    private(set) var conversions = 0

    /// The event tap works and the language models are in memory.
    var isReady: Bool { tap != nil && detector != nil }
    /// A selection gesture or a plain paste changes the clipboard at this time.
    var isUsingClipboard: Bool { selectionBusy }

    @ObservationIgnored private let log = Logger(subsystem: "com.andrewkomkov.KeySwitch", category: "engine")
    @ObservationIgnored private let settings = Settings.shared
    @ObservationIgnored private var tap: CFMachPort?
    @ObservationIgnored private var runLoopSource: CFRunLoopSource?
    @ObservationIgnored private var buffer = WordBuffer()
    @ObservationIgnored private var shiftTaps = TapRecognizer()
    @ObservationIgnored private var optionTaps = TapRecognizer()
    @ObservationIgnored private var detector: Detector?
    @ObservationIgnored private var learner = WordLearner()
    @ObservationIgnored private var yoficator: Yoficator?
    @ObservationIgnored private var emojiCodes = EmojiCodes(list: "")
    @ObservationIgnored private var layouts: [Layout] = []
    /// What the word looked like before the detector converted it.
    @ObservationIgnored private var autoConvertedFrom = ""
    /// Terms that the typo correction must leave alone.
    @ObservationIgnored private var technicalWords: Set<String> = []
    /// The typed and the shown text of the word whose spelling was corrected.
    @ObservationIgnored private var typo: (typed: String, shown: String)?
    @ObservationIgnored private var layoutBeforeTap: Layout?
    /// The text that the last selection gesture inserted. Any key or click forgets it.
    @ObservationIgnored private var inserted: String?
    @ObservationIgnored private var selectionBusy = false
    /// For the self-test: a list in place of the text replacements of macOS.
    @ObservationIgnored var replacementsOverride: TextReplacements?
    /// For the self-test: skip the Accessibility read and go through the clipboard.
    @ObservationIgnored var selectionThroughClipboardOnly = false
    /// Bundle identifier of the app that gets the keys. Can be KeySwitch.
    @ObservationIgnored private var focusedBundleID: String?

    private enum KeyCode {
        static let space: UInt16 = 49
        static let backspace: UInt16 = 51
        static let returnKeys: Set<UInt16> = [36, 76]
        static let v: UInt16 = 9
    }

    private init() {}

    func start() {
        layouts = InputSources.layouts()
        DistributedNotificationCenter.default().addObserver(
            forName: .init(kTISNotifyEnabledKeyboardInputSourcesChanged as String), object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.layouts = InputSources.layouts() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated { self?.applicationActivated(app) }
        }
        applicationActivated(NSWorkspace.shared.frontmostApplication)

        Task.detached(priority: .userInitiated) {
            let (detector, technicalWords, yoficator, emojiCodes) = Self.loadDetector()
            await MainActor.run {
                self.emojiCodes = emojiCodes
                self.detector = detector
                self.technicalWords = technicalWords
                self.yoficator = yoficator
            }
        }

        refreshTrust()
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshTrust() }
        }
    }

    /// Shows the system prompt that asks for the Accessibility permission.
    func requestTrust() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// Forgets the current phrase and a tap in progress.
    func resetInputState() {
        buffer.reset()
        interruptTaps()
        inserted = nil
    }

    private func interruptTaps() {
        shiftTaps.interrupt()
        optionTaps.interrupt()
    }

    // MARK: - Setup

    private nonisolated static func loadDetector() -> (Detector?, Set<String>, Yoficator?, EmojiCodes) {
        func list(_ name: String) -> String? {
            guard let url = Bundle.main.url(forResource: name, withExtension: "txt") else { return nil }
            return try? String(contentsOf: url, encoding: .utf8)
        }
        guard let russian = list("ru"), let english = list("en") else { return (nil, [], nil, EmojiCodes(list: "")) }
        let technical = list("en-tech") ?? ""
        let detector = Detector(models: [
            .russian(wordList: russian),
            .english(wordList: english + technical),
        ])
        let technicalWords = Set(technical.split(separator: "\n").map(String.init))
        return (detector, technicalWords, list("ru-yo").map(Yoficator.init(dictionary:)),
                EmojiCodes(list: list("emoji") ?? ""))
    }

    private func refreshTrust() {
        let trusted = AXIsProcessTrusted()
        if trusted != isTrusted { isTrusted = trusted }
        if trusted, tap == nil {
            installTap()
        } else if !trusted, tap != nil {
            removeTap()
        }
    }

    private func installTap() {
        let types: [CGEventType] = [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown, .otherMouseDown]
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            let engine = Unmanaged<Engine>.fromOpaque(userInfo!).takeUnretainedValue()
            let pass = MainActor.assumeIsolated { engine.handle(type: type, event: event) }
            return pass ? Unmanaged.passUnretained(event) : nil
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask, callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque())
        else {
            log.error("Could not create the event tap")
            return
        }
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        runLoopSource = source
        log.notice("Event tap installed")
    }

    private func removeTap() {
        if let runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
        tap = nil
        runLoopSource = nil
        buffer.reset()
        log.notice("Event tap removed")
    }

    private func applicationActivated(_ app: NSRunningApplication?) {
        resetInputState()
        focusedBundleID = app?.bundleIdentifier
        if let app, app.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            frontApp = app
        }
    }

    // MARK: - Events

    /// Returns `false` to swallow the event.
    private func handle(type: CGEventType, event: CGEvent) -> Bool {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return true
        case _ where Typist.isOwn(event) || !settings.isEnabled:
            return true
        case .flagsChanged:
            flagsChanged(event)
            return true
        case .keyDown where ClipboardSearch.shared.isVisible:
            // The search field gets the text as typed.
            return true
        case .keyDown:
            return keyDown(event)
        default:
            resetInputState()
            return true
        }
    }

    private func flagsChanged(_ event: CGEvent) {
        let flags = event.flags
        let time = ProcessInfo.processInfo.systemUptime
        let shift = flags.contains(.maskShift), option = flags.contains(.maskAlternate)
        let others = !flags.isDisjoint(with: [.maskCommand, .maskControl, .maskSecondaryFn])

        switch shiftTaps.flagsChanged(isDown: shift, otherModifiers: others || option, time: time) {
        case .none:
            break
        case .single:
            layoutBeforeTap = InputSources.current()
            if settings.shiftSwitches { selectNextLayout() }
        case .double:
            guard settings.doubleShiftConverts, !ClipboardSearch.shared.isVisible else { break }
            if buffer.typoCorrected {
                revertTypo()
                break
            }
            if buffer.isEmpty {
                convertSelection()
                break
            }
            // The first tap already selected the target layout, unless that gesture is off.
            if !settings.shiftSwitches { selectNextLayout() }
            detector?.learned = settings.learnedByLanguage
            learnFromManualConversion()
            convertManually()
        case .repeated:
            if settings.doubleShiftConverts, buffer.extend() { convertManually() }
        }

        switch optionTaps.flagsChanged(isDown: option, otherModifiers: others || shift, time: time) {
        case .none, .single:
            break
        case .double, .repeated:
            guard settings.caseGesture, !ClipboardSearch.shared.isVisible else { break }
            if buffer.isEmpty {
                transformSelection { CaseCycler.next($0) }
            } else {
                changeCase()
            }
        }
    }

    private func keyDown(_ event: CGEvent) -> Bool {
        interruptTaps()
        inserted = nil
        let flags = event.flags
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift])
        if keyCode == KeyCode.v, modifiers == [.maskControl, .maskAlternate],
           settings.clipboardHistory, settings.clipboardSearch {
            buffer.reset()
            ClipboardSearch.shared.show()
            return false
        }
        if keyCode == KeyCode.v, modifiers == [.maskCommand, .maskShift], pastePlain() {
            buffer.reset()
            return false
        }
        guard flags.isDisjoint(with: [.maskCommand, .maskControl, .maskAlternate]) else {
            buffer.reset()
            return true
        }
        let key = Keystroke(
            keyCode: keyCode, shift: flags.contains(.maskShift), capsLock: flags.contains(.maskAlphaShift))

        if keyCode == KeyCode.backspace {
            buffer.deleteLast()
        } else if keyCode == KeyCode.space {
            detector?.learned = settings.learnedByLanguage
            if changeFinishedWord() {
                Typist.press(keyCode)
                buffer.append(key, isSpace: true)
                return false
            }
            countTypedWord()
            buffer.append(key, isSpace: true)
        } else if KeyCode.returnKeys.contains(keyCode) {
            detector?.learned = settings.learnedByLanguage
            let converted = changeFinishedWord()
            if !converted { countTypedWord() }
            buffer.reset()
            if converted {
                Typist.press(keyCode, flags: flags.intersection(.maskShift))
                return false
            }
        } else if let layout = InputSources.current(), Self.isPrintable(layout.text(for: [key])) {
            buffer.append(key, isSpace: false)
        } else {
            buffer.reset()
        }
        return true
    }

    private static func isPrintable(_ text: String) -> Bool {
        guard text.count == 1, let scalar = text.unicodeScalars.first else { return false }
        // 0xF700...0xF8FF: the private codes of the arrow and function keys.
        return scalar.value >= 0x20 && scalar.value != 0x7F && !(0xF700...0xF8FF).contains(scalar.value)
    }

    // MARK: - Actions

    private func selectNextLayout() {
        if let next = layout(after: InputSources.current()) { InputSources.select(next) }
    }

    private func layout(after layout: Layout?) -> Layout? {
        guard layouts.count > 1, let layout else { return nil }
        let index = layouts.firstIndex(of: layout) ?? -1
        return layouts[(index + 1) % layouts.count]
    }

    /// Converts the selected text between the layout from before the gesture and the one
    /// that the first tap selected.
    private func convertSelection() {
        guard let current = InputSources.current() else { return }
        let first = layoutBeforeTap ?? current
        guard let second = first == current ? layout(after: first) : current else { return }

        var pairs: [(Character, Character)] = []
        for shift in [false, true] {
            for keyCode in UInt16(0)..<52 {
                let key = [Keystroke(keyCode: keyCode, shift: shift)]
                let a = first.text(for: key), b = second.text(for: key)
                if Self.isPrintable(a), Self.isPrintable(b), a != " " { pairs.append((Character(a), Character(b))) }
            }
        }
        let converter = LayoutConverter(pairs: pairs)
        transformSelection { text in
            guard let direction = converter.direction(for: text) else { return nil }
            InputSources.select(direction == .forward ? second : first)
            return converter.convert(text, direction)
        }
    }

    /// Replaces the selected text, or the text that the last gesture inserted, with its
    /// transformed form. The clipboard gets its content back.
    private func transformSelection(_ transform: @escaping (String) -> String?) {
        guard settings.selectionGestures, !selectionBusy else { return }
        selectionBusy = true
        Task {
            defer { selectionBusy = false }
            var clipboard: [[NSPasteboard.PasteboardType: Data]]?
            defer { if let clipboard { Selection.restore(clipboard) } }

            let source: String
            if let inserted {
                source = inserted
            } else {
                let reading: Selection.Reading = selectionThroughClipboardOnly ? .unknown : Selection.read()
                switch reading {
                case .text(let text):
                    source = text
                case .empty:
                    return
                case .unknown:
                    clipboard = Selection.snapshot()
                    guard let copied = await Selection.copy() else { return }
                    source = copied
                }
            }
            guard source.count <= Selection.maxLength, let result = transform(source), result != source else { return }

            if clipboard == nil { clipboard = Selection.snapshot() }
            if inserted != nil { Typist.press(KeyCode.backspace, times: source.count) }
            await Selection.paste(result)
            inserted = result
            conversions += 1
        }
    }

    /// Pastes the text of the clipboard without its format. The clipboard gets its content
    /// back. Returns `false` if the front app must get the keys.
    private func pastePlain() -> Bool {
        guard settings.plainPaste, !settings.isExcluded(focusedBundleID),
              let text = NSPasteboard.general.string(forType: .string), !text.isEmpty
        else { return false }
        guard !selectionBusy else { return true }
        selectionBusy = true
        Task {
            defer { selectionBusy = false }
            let clipboard = Selection.snapshot()
            await Selection.paste(text)
            Selection.restore(clipboard)
        }
        return true
    }

    /// Replaces the word and its spaces with the same keys read in the active layout.
    private func convertManually() {
        let keys = buffer.all
        guard !keys.isEmpty, let target = InputSources.current() else { return }
        replace(count: keys.count, with: yoficated(target.text(for: keys)))
        if buffer.autoConverted {
            settings.addException(autoConvertedFrom)
            buffer.autoConverted = false
        }
        buffer.manuallyConverted = true
    }

    /// Counts a finished word that stays as typed. The third use makes it a learned word.
    private func countTypedWord() {
        guard settings.learnWords, let detector,
              !buffer.isEmpty, buffer.trailingSpaces.isEmpty, !buffer.autoConverted, !buffer.typoCorrected,
              !settings.isExcluded(focusedBundleID),
              let layout = InputSources.current(), let other = otherLayout(than: layout)
        else { return }
        let word = Detector.core(of: layout.text(for: buffer.word))
        let learnable = detector.isLearnable(
            word, language: layout.language,
            other: other.text(for: buffer.word), otherLanguage: other.language)
        if learnable, learner.observe(word, language: layout.language) {
            settings.setLearned(true, word: word, language: layout.language)
        }
    }

    /// The user converts the word by hand: the new reading is what they want, the old one is not.
    private func learnFromManualConversion() {
        guard settings.learnWords, let detector, !buffer.isEmpty,
              !settings.isExcluded(focusedBundleID),
              let target = InputSources.current(), let source = layoutBeforeTap, source != target
        else { return }
        let old = source.text(for: buffer.word)
        let new = Detector.core(of: target.text(for: buffer.word))
        // Asked before the old reading is forgotten: a conversion back must not teach it.
        let learnable = detector.isLearnable(
            new, language: target.language, other: old, otherLanguage: source.language, confirmed: true)
        learner.forget(Detector.core(of: old), language: source.language)
        settings.setLearned(false, word: Detector.core(of: old), language: source.language)
        if learnable { settings.setLearned(true, word: new, language: target.language) }
    }

    /// The first enabled layout of another language that has a model.
    private func otherLayout(than layout: Layout) -> Layout? {
        layouts.first { $0.language != layout.language && detector?.supports($0.language) == true }
    }

    /// Gives the last word its next letter case.
    private func changeCase() {
        guard !buffer.isEmpty, !buffer.typoCorrected, let layout = InputSources.current() else { return }
        let keys = buffer.word
        let text = layout.text(for: keys)
        let changed = CaseCycler.next(text)
        guard text.count == keys.count, changed.count == keys.count, changed != text else { return }

        // The same keys with or without Shift, so that the buffer stays true to the screen.
        var replacement: [Keystroke] = []
        for (key, character) in zip(keys, changed) {
            let variants = [false, true].map { Keystroke(keyCode: key.keyCode, shift: $0) }
            guard let match = variants.first(where: { layout.text(for: [$0]) == String(character) }) else { return }
            replacement.append(match)
        }
        let spaces = String(repeating: " ", count: buffer.trailingSpaces.count)
        replace(count: keys.count + spaces.count, with: changed + spaces)
        buffer.replaceWord(replacement)
        buffer.manuallyConverted = true
    }

    /// One automatic change for the finished word. The first function that acts wins.
    private func changeFinishedWord() -> Bool {
        expandShortcut() || expandEmojiCode() || convertAutomatically() || fixCapitals() || correctTypo()
            || yoficate()
    }

    /// Replaces a finished code such as `:fire:` with its emoji. A double Shift tap brings
    /// the code back, the same as after a typo correction.
    private func expandEmojiCode() -> Bool {
        guard settings.emojiCodes,
              !buffer.isEmpty, buffer.trailingSpaces.isEmpty,
              !buffer.autoConverted, !buffer.manuallyConverted, !buffer.typoCorrected,
              !settings.isExcluded(focusedBundleID),
              let layout = InputSources.current()
        else { return false }

        let keys = buffer.word
        let typed = layout.text(for: keys)
        guard typed.count == keys.count, !settings.exceptionSet.contains(Detector.core(of: typed)) else { return false }
        // The colon is on a different key in a Russian layout, so the keys can be a code
        // only in the English reading.
        let english = layouts.first { $0.language == "en" }
        guard let shown = emojiCodes.emoji(for: typed) ?? english.flatMap({ emojiCodes.emoji(for: $0.text(for: keys)) })
        else { return false }

        replace(count: keys.count, with: shown)
        buffer.typoCorrected = true
        typo = (typed, shown)
        return true
    }

    /// Replaces a finished shortcut of the macOS text replacements with its phrase. A double
    /// Shift tap brings the shortcut back, the same as after a typo correction.
    private func expandShortcut() -> Bool {
        guard settings.systemReplacements,
              !buffer.isEmpty, buffer.trailingSpaces.isEmpty,
              !buffer.autoConverted, !buffer.manuallyConverted, !buffer.typoCorrected,
              !settings.isExcluded(focusedBundleID),
              let layout = InputSources.current()
        else { return false }

        let keys = buffer.word
        let typed = layout.text(for: keys)
        let replacements = replacementsOverride ?? SystemReplacements.current
        guard typed.count == keys.count, !settings.exceptionSet.contains(Detector.core(of: typed)),
              let shown = replacements.expansion(for: typed)
        else { return false }

        replace(count: keys.count, with: shown)
        buffer.typoCorrected = true
        typo = (typed, shown)
        return true
    }

    /// Converts the finished word if the detector says that the layout was wrong.
    private func convertAutomatically() -> Bool {
        guard settings.autoSwitch, let detector,
              !buffer.isEmpty, buffer.trailingSpaces.isEmpty,
              !buffer.autoConverted, !buffer.manuallyConverted,
              !settings.isExcluded(focusedBundleID),
              let current = InputSources.current(), detector.supports(current.language),
              let other = otherLayout(than: current)
        else { return false }

        let keys = buffer.word
        let currentText = current.text(for: keys)
        let otherText = other.text(for: keys)
        guard currentText.count == keys.count,
              detector.shouldConvert(
                current: currentText, language: current.language,
                other: otherText, otherLanguage: other.language,
                exceptions: settings.exceptionSet)
        else { return false }

        replace(count: keys.count, with: sentenceCased(yoficated(withoutExtraCapitals(otherText, language: other.language))))
        InputSources.select(other)
        buffer.autoConverted = true
        autoConvertedFrom = Detector.core(of: currentText)
        return true
    }

    /// Gives a finished word such as `ПРивет` one capital. A double Shift tap brings the
    /// typed word back, the same as after a typo correction.
    private func fixCapitals() -> Bool {
        guard !buffer.isEmpty, buffer.trailingSpaces.isEmpty,
              !buffer.autoConverted, !buffer.manuallyConverted, !buffer.typoCorrected,
              !settings.isExcluded(focusedBundleID),
              let layout = InputSources.current()
        else { return false }

        let keys = buffer.word
        let typed = layout.text(for: keys)
        let fixed = withoutExtraCapitals(typed, language: layout.language)
        guard typed.count == keys.count, fixed != typed else { return false }

        let shown = sentenceCased(yoficated(fixed))
        replace(count: keys.count, with: shown)
        buffer.typoCorrected = true
        typo = (typed, shown)
        return true
    }

    /// The text with one capital in place of accidental ones, if the option is on.
    private func withoutExtraCapitals(_ text: String, language: String) -> String {
        guard settings.fixCapitals, let detector,
              !settings.exceptionSet.contains(Detector.core(of: text))
        else { return text }
        return CaseFixer.fixed(text) { detector.rank(of: $0, language: language) != nil } ?? text
    }

    /// Replaces the finished word with the confident correction of the spelling checker.
    private func correctTypo() -> Bool {
        guard settings.fixTypos, let detector,
              !buffer.isEmpty, buffer.trailingSpaces.isEmpty,
              !buffer.autoConverted, !buffer.manuallyConverted, !buffer.typoCorrected,
              !settings.isExcluded(focusedBundleID),
              let layout = InputSources.current()
        else { return false }

        let keys = buffer.word
        let typed = layout.text(for: keys)
        guard typed.count == keys.count,
              let corrected = TypoPolicy.correctedText(
                for: typed, exceptions: settings.exceptionSet,
                rank: { detector.rank(of: $0, language: layout.language) },
                isProtected: { self.technicalWords.contains($0.lowercased()) },
                suggest: { SpellCorrector.correction(for: $0, language: layout.language) })
        else { return false }

        let shown = sentenceCased(corrected)
        replace(count: keys.count, with: shown)
        buffer.typoCorrected = true
        typo = (typed, shown)
        return true
    }

    /// The last step for a finished word: `ё`, and a capital at the start of a sentence.
    /// A double Shift tap brings the typed word back, the same as after a typo correction.
    private func yoficate() -> Bool {
        guard !buffer.isEmpty, buffer.trailingSpaces.isEmpty,
              !buffer.autoConverted, !buffer.manuallyConverted, !buffer.typoCorrected,
              !settings.isExcluded(focusedBundleID),
              let layout = InputSources.current()
        else { return false }

        let keys = buffer.word
        let typed = layout.text(for: keys)
        let shown = sentenceCased(yoficated(typed))
        guard typed.count == keys.count, shown != typed else { return false }

        replace(count: keys.count, with: shown)
        buffer.typoCorrected = true
        typo = (typed, shown)
        return true
    }

    /// The text with a capital first letter if it starts a sentence and the option is on.
    /// The word before it tells that: the user typed it in the layout that is active now.
    private func sentenceCased(_ text: String) -> String {
        guard settings.capitalizeSentences, let layout = InputSources.current(),
              !settings.exceptionSet.contains(Detector.core(of: text))
        else { return text }
        return SentenceCase.capitalized(text, after: layout.text(for: buffer.previousWord)) ?? text
    }

    /// The text with `ё` in the words that need it, if the option is on.
    private func yoficated(_ text: String) -> String {
        guard settings.yofication, let yoficator else { return text }
        return yoficator.restore(text, exceptions: settings.exceptionSet)
    }

    /// Brings back the typed spelling. The first Shift tap changed the layout, and the typo
    /// was in the right one, so the layout goes back too.
    private func revertTypo() {
        guard let typo else { return }
        let spaces = String(repeating: " ", count: buffer.trailingSpaces.count)
        replace(count: typo.shown.count + spaces.count, with: typo.typed + spaces)
        settings.addException(Detector.core(of: typo.typed))
        buffer.typoCorrected = false
        buffer.manuallyConverted = true
        self.typo = nil
        if settings.shiftSwitches, let layoutBeforeTap { InputSources.select(layoutBeforeTap) }
    }

    private func replace(count: Int, with text: String) {
        Typist.press(KeyCode.backspace, times: count)
        Typist.type(text)
        conversions += 1
        if settings.playSound { NSSound(named: "Pop")?.play() }
    }
}
