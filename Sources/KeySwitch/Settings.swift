import Foundation
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
        ])
        isEnabled = defaults.bool(forKey: Key.isEnabled)
        shiftSwitches = defaults.bool(forKey: Key.shiftSwitches)
        doubleShiftConverts = defaults.bool(forKey: Key.doubleShiftConverts)
        autoSwitch = defaults.bool(forKey: Key.autoSwitch)
        playSound = defaults.bool(forKey: Key.playSound)
        excludedApps = defaults.stringArray(forKey: Key.excludedApps) ?? []
        let exceptions = defaults.stringArray(forKey: Key.exceptions) ?? []
        self.exceptions = exceptions
        exceptionSet = Set(exceptions)
    }

    func addException(_ word: String) {
        guard !word.isEmpty, !exceptionSet.contains(word) else { return }
        exceptions.append(word)
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
