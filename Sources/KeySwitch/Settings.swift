import Foundation
import KeySwitchCore
import Observation
import ServiceManagement

/// User settings, stored in UserDefaults.
@Observable
final class Settings {
    static let shared = Settings()

    var isEnabled: Bool { didSet { defaults.set(isEnabled, forKey: Key.isEnabled) } }
    var shiftSwitches: Bool { didSet { defaults.set(shiftSwitches, forKey: Key.shiftSwitches) } }
    var doubleShiftConverts: Bool { didSet { defaults.set(doubleShiftConverts, forKey: Key.doubleShiftConverts) } }
    var autoSwitch: Bool { didSet { defaults.set(autoSwitch, forKey: Key.autoSwitch) } }
    var caseGesture: Bool { didSet { defaults.set(caseGesture, forKey: Key.caseGesture) } }
    var selectionGestures: Bool { didSet { defaults.set(selectionGestures, forKey: Key.selectionGestures) } }
    var plainPaste: Bool { didSet { defaults.set(plainPaste, forKey: Key.plainPaste) } }
    var learnWords: Bool { didSet { defaults.set(learnWords, forKey: Key.learnWords) } }
    /// Learned words as `language:word`.
    var learnedWords: [String] {
        didSet {
            defaults.set(learnedWords, forKey: Key.learnedWords)
            learnedByLanguage = Self.byLanguage(learnedWords)
        }
    }
    private(set) var learnedByLanguage: [String: Set<String>]
    var fixTypos: Bool { didSet { defaults.set(fixTypos, forKey: Key.fixTypos) } }
    var yofication: Bool { didSet { defaults.set(yofication, forKey: Key.yofication) } }
    var fixCapitals: Bool { didSet { defaults.set(fixCapitals, forKey: Key.fixCapitals) } }
    var systemReplacements: Bool { didSet { defaults.set(systemReplacements, forKey: Key.systemReplacements) } }
    var clipboardHistory: Bool { didSet { defaults.set(clipboardHistory, forKey: Key.clipboardHistory) } }
    var clipboardLimit: Int { didSet { defaults.set(clipboardLimit, forKey: Key.clipboardLimit) } }
    var playSound: Bool { didSet { defaults.set(playSound, forKey: Key.playSound) } }
    /// Bundle identifiers of the apps where the detector is off.
    var excludedApps: [String] { didSet { defaults.set(excludedApps, forKey: Key.excludedApps) } }
    /// Words the user reverted after an automatic conversion.
    var exceptions: [String] {
        didSet {
            defaults.set(exceptions, forKey: Key.exceptions)
            exceptionSet = Set(exceptions)
        }
    }
    private(set) var exceptionSet: Set<String>
    private(set) var launchAtLoginError: String?

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                launchAtLoginError = nil
            } catch {
                launchAtLoginError = error.localizedDescription
            }
        }
    }

    private let defaults = UserDefaults.standard

    private enum Key {
        static let isEnabled = "isEnabled"
        static let shiftSwitches = "shiftSwitches"
        static let doubleShiftConverts = "doubleShiftConverts"
        static let autoSwitch = "autoSwitch"
        static let playSound = "playSound"
        static let fixTypos = "fixTypos"
        static let yofication = "yofication"
        static let fixCapitals = "fixCapitals"
        static let systemReplacements = "systemReplacements"
        static let caseGesture = "caseGesture"
        static let learnWords = "learnWords"
        static let learnedWords = "learnedWords"
        static let selectionGestures = "selectionGestures"
        static let plainPaste = "plainPaste"
        static let clipboardHistory = "clipboardHistory"
        static let clipboardLimit = "clipboardLimit"
        static let excludedApps = "excludedApps"
        static let exceptions = "exceptions"
    }

    private init() {
        defaults.register(defaults: [
            Key.isEnabled: true,
            Key.shiftSwitches: true,
            Key.doubleShiftConverts: true,
            Key.autoSwitch: true,
            Key.playSound: false,
            Key.caseGesture: true,
            Key.selectionGestures: true,
            Key.plainPaste: true,
            Key.fixCapitals: true,
            Key.systemReplacements: true,
            Key.clipboardLimit: ClipboardHistory.defaultLimit,
        ])
        isEnabled = defaults.bool(forKey: Key.isEnabled)
        shiftSwitches = defaults.bool(forKey: Key.shiftSwitches)
        doubleShiftConverts = defaults.bool(forKey: Key.doubleShiftConverts)
        autoSwitch = defaults.bool(forKey: Key.autoSwitch)
        playSound = defaults.bool(forKey: Key.playSound)
        fixTypos = defaults.bool(forKey: Key.fixTypos)
        yofication = defaults.bool(forKey: Key.yofication)
        fixCapitals = defaults.bool(forKey: Key.fixCapitals)
        systemReplacements = defaults.bool(forKey: Key.systemReplacements)
        caseGesture = defaults.bool(forKey: Key.caseGesture)
        learnWords = defaults.bool(forKey: Key.learnWords)
        let learnedWords = defaults.stringArray(forKey: Key.learnedWords) ?? []
        self.learnedWords = learnedWords
        learnedByLanguage = Self.byLanguage(learnedWords)
        selectionGestures = defaults.bool(forKey: Key.selectionGestures)
        plainPaste = defaults.bool(forKey: Key.plainPaste)
        clipboardHistory = defaults.bool(forKey: Key.clipboardHistory)
        clipboardLimit = defaults.integer(forKey: Key.clipboardLimit)
        excludedApps = defaults.stringArray(forKey: Key.excludedApps) ?? []
        let exceptions = defaults.stringArray(forKey: Key.exceptions) ?? []
        self.exceptions = exceptions
        exceptionSet = Set(exceptions)
    }

    func addException(_ word: String) {
        guard !word.isEmpty, !exceptionSet.contains(word) else { return }
        exceptions.append(word)
    }

    func setLearned(_ learned: Bool, word: String, language: String) {
        let entry = WordLearner.entry(word, language: language)
        if learned, !learnedWords.contains(entry) {
            learnedWords.append(entry)
        } else if !learned {
            learnedWords.removeAll { $0 == entry }
        }
    }

    private static func byLanguage(_ entries: [String]) -> [String: Set<String>] {
        var result: [String: Set<String>] = [:]
        for entry in entries {
            let parts = entry.split(separator: ":", maxSplits: 1)
            if parts.count == 2 { result[String(parts[0]), default: []].insert(String(parts[1])) }
        }
        return result
    }

    func isExcluded(_ bundleID: String?) -> Bool {
        bundleID.map(excludedApps.contains) ?? false
    }

    func toggleExclusion(of bundleID: String) {
        if let index = excludedApps.firstIndex(of: bundleID) {
            excludedApps.remove(at: index)
        } else {
            excludedApps.append(bundleID)
        }
    }
}
