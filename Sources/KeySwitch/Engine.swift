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

    @ObservationIgnored private let log = Logger(subsystem: "com.andrewkomkov.KeySwitch", category: "engine")
    @ObservationIgnored private let settings = Settings.shared
    @ObservationIgnored private var tap: CFMachPort?
    @ObservationIgnored private var runLoopSource: CFRunLoopSource?
    @ObservationIgnored private var buffer = WordBuffer()
    @ObservationIgnored private var recognizer = ShiftTapRecognizer()
    @ObservationIgnored private var detector: Detector?
    @ObservationIgnored private var layouts: [Layout] = []
    /// What the word looked like before the detector converted it.
    @ObservationIgnored private var autoConvertedFrom = ""

    private enum KeyCode {
        static let space: UInt16 = 49
        static let backspace: UInt16 = 51
        static let returnKeys: Set<UInt16> = [36, 76]
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
            let detector = Self.loadDetector()
            await MainActor.run { self.detector = detector }
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

    // MARK: - Setup

    private nonisolated static func loadDetector() -> Detector? {
        func list(_ name: String) -> String? {
            guard let url = Bundle.main.url(forResource: name, withExtension: "txt") else { return nil }
            return try? String(contentsOf: url, encoding: .utf8)
        }
        guard let russian = list("ru"), let english = list("en") else { return nil }
        return Detector(models: [
            .russian(wordList: russian),
            .english(wordList: english + (list("en-tech") ?? "")),
        ])
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
        buffer.reset()
        recognizer.interrupt()
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
        case .keyDown:
            return keyDown(event)
        default:
            buffer.reset()
            recognizer.interrupt()
            return true
        }
    }

    private func flagsChanged(_ event: CGEvent) {
        let flags = event.flags
        let action = recognizer.flagsChanged(
            shiftDown: flags.contains(.maskShift),
            otherModifiers: !flags.isDisjoint(with: [.maskCommand, .maskControl, .maskAlternate, .maskSecondaryFn]),
            time: ProcessInfo.processInfo.systemUptime)
        switch action {
        case .none:
            break
        case .switchLayout:
            if settings.shiftSwitches { selectNextLayout() }
        case .convert:
            guard settings.doubleShiftConverts else { break }
            // The first tap already selected the target layout, unless that gesture is off.
            if !settings.shiftSwitches { selectNextLayout() }
            convertManually()
        }
    }

    private func keyDown(_ event: CGEvent) -> Bool {
        recognizer.interrupt()
        let flags = event.flags
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        guard flags.isDisjoint(with: [.maskCommand, .maskControl, .maskAlternate]) else {
            buffer.reset()
            return true
        }
        let key = Keystroke(
            keyCode: keyCode, shift: flags.contains(.maskShift), capsLock: flags.contains(.maskAlphaShift))

        if keyCode == KeyCode.backspace {
            buffer.deleteLast()
        } else if keyCode == KeyCode.space {
            if convertAutomatically() {
                Typist.press(keyCode)
                buffer.append(key, isSpace: true)
                return false
            }
            buffer.append(key, isSpace: true)
        } else if KeyCode.returnKeys.contains(keyCode) {
            let converted = convertAutomatically()
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
        guard layouts.count > 1, let current = InputSources.current() else { return }
        let index = layouts.firstIndex(of: current) ?? -1
        InputSources.select(layouts[(index + 1) % layouts.count])
    }

    /// Replaces the word and its spaces with the same keys read in the active layout.
    private func convertManually() {
        let keys = buffer.all
        guard !keys.isEmpty, let target = InputSources.current() else { return }
        replace(count: keys.count, with: target.text(for: keys))
        if buffer.autoConverted {
            settings.addException(autoConvertedFrom)
            buffer.autoConverted = false
        }
        buffer.manuallyConverted = true
    }

    /// Converts the finished word if the detector says that the layout was wrong.
    private func convertAutomatically() -> Bool {
        guard settings.autoSwitch, let detector,
              !buffer.isEmpty, buffer.trailingSpaces.isEmpty,
              !buffer.autoConverted, !buffer.manuallyConverted,
              !settings.isExcluded(frontApp?.bundleIdentifier),
              let current = InputSources.current(), detector.supports(current.language),
              let other = layouts.first(where: { $0.language != current.language && detector.supports($0.language) })
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

        replace(count: keys.count, with: otherText)
        InputSources.select(other)
        buffer.autoConverted = true
        autoConvertedFrom = Detector.core(of: currentText)
        return true
    }

    private func replace(count: Int, with text: String) {
        Typist.press(KeyCode.backspace, times: count)
        Typist.type(text)
        conversions += 1
        if settings.playSound { NSSound(named: "Pop")?.play() }
    }
}
