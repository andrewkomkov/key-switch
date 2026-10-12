import KeySwitchCore
import SwiftUI

struct SettingsView: View {
    @Bindable var settings: Settings
    let engine: Engine
    let clipboard: ClipboardMonitor

    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") { GeneralSettings(settings: settings, engine: engine) }
            Tab("Apps", systemImage: "app.badge.checkmark") { AppSettings(settings: settings) }
            Tab("Exceptions", systemImage: "text.badge.xmark") { ExceptionSettings(settings: settings) }
            Tab("Learned", systemImage: "graduationcap") { LearnedSettings(settings: settings) }
            Tab("Clipboard", systemImage: "clipboard") { ClipboardSettings(settings: settings, clipboard: clipboard) }
            Tab("About", systemImage: "info.circle") { AboutView() }
        }
        .scenePadding()
        .frame(width: 520, height: 680)
    }
}

private struct GeneralSettings: View {
    @Bindable var settings: Settings
    let engine: Engine

    var body: some View {
        Form {
            Section {
                Toggle("Enable KeySwitch", isOn: $settings.isEnabled)
                Toggle("Open at login", isOn: $settings.launchAtLogin)
                if let error = settings.launchAtLoginError {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            }
            Section {
                Toggle("Tap Shift to switch the layout", isOn: $settings.shiftSwitches)
                Toggle("Double-tap Shift to retype the last word", isOn: $settings.doubleShiftConverts)
                Toggle("Double-tap Option to change the case", isOn: $settings.caseGesture)
                Toggle("Apply the gestures to the selected text", isOn: $settings.selectionGestures)
                Toggle("Paste without formatting with ⌘⇧V", isOn: $settings.plainPaste)
            } header: {
                Text("Gestures")
            } footer: {
                Text("Each more Shift tap in a row takes one more word to the left. Each more Option tap gives the next case: hello, Hello, HELLO.")
            }
            Section {
                Toggle("Switch the layout automatically", isOn: $settings.autoSwitch)
            } header: {
                Text("Automatic")
            } footer: {
                Text("When you finish a word with Space or Return, KeySwitch checks it against a dictionary and a letter model. Double-tap Shift to undo: the word becomes an exception.")
            }
            Section {
                Toggle("Learn the words that I type often", isOn: $settings.learnWords)
            } footer: {
                Text("A word that you type three times, or convert by hand, goes to the Learned list and counts as a dictionary word. The list is stored on this Mac.")
            }
            Section {
                Toggle("Fix accidental capitals", isOn: $settings.fixCapitals)
                Toggle("Capitalize the first word of a sentence", isOn: $settings.capitalizeSentences)
                Toggle("Fix typos", isOn: $settings.fixTypos)
                Toggle("Put the letter ё back", isOn: $settings.yofication)
            } header: {
                Text("Spelling")
            } footer: {
                Text("A dictionary word such as HEllo gets one capital. Typo correction uses the macOS spelling checker and replaces a word only when the correction is a frequent word. The letter ё goes only into the words that always have it: еще becomes ещё, and все stays. Double-tap Shift to undo: the word becomes an exception.")
            }
            Section {
                Toggle("Use the text replacements of macOS in all apps", isOn: $settings.systemReplacements)
                Toggle("Replace emoji codes such as :fire:", isOn: $settings.emojiCodes)
                LabeledContent("Replacements in System Settings", value: SystemReplacements.current.count, format: .number)
                Button("Open Keyboard Settings…") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
            } header: {
                Text("Text replacements")
            } footer: {
                Text("KeySwitch reads the list of System Settings, Keyboard, Text Replacements. It applies the list in the apps that ignore it, such as browsers and terminals. Double-tap Shift to undo: the shortcut becomes an exception.")
            }
            Section {
                Toggle("Play a sound on conversion", isOn: $settings.playSound)
                LabeledContent("Conversions this session", value: engine.conversions, format: .number)
            }
        }
        .formStyle(.grouped)
    }
}

private struct AppSettings: View {
    @Bindable var settings: Settings

    var body: some View {
        RemovableList(
            items: $settings.excludedApps,
            title: { bundleID in
                NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
                    .map { FileManager.default.displayName(atPath: $0.path) } ?? bundleID
            },
            empty: "No excluded apps",
            hint: "Automatic switching and ⌘⇧V are off in these apps. Add an app from the menu bar while it is in front.")
    }
}

private struct ClipboardSettings: View {
    @Bindable var settings: Settings
    let clipboard: ClipboardMonitor

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Keep a clipboard history", isOn: $settings.clipboardHistory)
            Picker("Entries to keep", selection: $settings.clipboardLimit) {
                ForEach(ClipboardHistory.limits, id: \.self) { Text($0, format: .number) }
            }
            .fixedSize()
            Toggle("Search the history with ⌃⌥V", isOn: $settings.clipboardSearch)
            Text("KeySwitch keeps the text and the images that you copy in a folder on this Mac, and shows them in its menu. Password managers mark their copies, and KeySwitch ignores those. A password that you copy from another app goes into the history.")
                .font(.footnote).foregroundStyle(.secondary)
            if NSPasteboard.general.accessBehavior == .alwaysDeny {
                Text("macOS does not let KeySwitch read the clipboard. Change this in System Settings, Privacy & Security.")
                    .font(.footnote).foregroundStyle(.red)
            }
            List {
                ForEach(clipboard.history.pinned + clipboard.history.recent) { entry in
                    HStack {
                        ClipboardEntryLabel(entry: entry, clipboard: clipboard)
                        Spacer()
                        Button(entry.pinned ? LocalizedStringKey("Unpin") : "Pin", systemImage: entry.pinned ? "pin.fill" : "pin") {
                            clipboard.togglePin(entry)
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        Button("Remove", systemImage: "minus.circle") { clipboard.remove(entry) }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                    }
                }
            }
            .overlay {
                if clipboard.history.entries.isEmpty {
                    ContentUnavailableView("Nothing copied yet", systemImage: "tray")
                }
            }
            .clipShape(.rect(cornerRadius: 10))
            Text("A pinned entry stays in the menu: the limit and Clear History leave it alone. To pin an entry, click its pin here, or hold Option and click the entry in the menu.")
                .font(.footnote).foregroundStyle(.secondary)
            Button("Clear History", action: clipboard.clear)
                .disabled(clipboard.history.recent.isEmpty)
        }
    }
}

private struct LearnedSettings: View {
    @Bindable var settings: Settings

    var body: some View {
        RemovableList(
            items: $settings.learnedWords,
            title: { entry in
                let parts = entry.split(separator: ":", maxSplits: 1)
                return parts.count == 2 ? "\(parts[1]) (\(parts[0].uppercased()))" : entry
            },
            empty: "No learned words",
            hint: "KeySwitch treats these words as dictionary words. Remove a word that got here by mistake.")
    }
}

private struct ExceptionSettings: View {
    @Bindable var settings: Settings
    @State private var newWord = ""

    var body: some View {
        VStack {
            RemovableList(
                items: $settings.exceptions,
                title: { $0 },
                empty: "No exceptions",
                hint: "KeySwitch never converts these words. A word gets here when you undo an automatic conversion.")
            HStack {
                TextField("Add a word", text: $newWord)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(add)
                Button("Add", action: add)
                    .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func add() {
        settings.addException(newWord.trimmingCharacters(in: .whitespaces).lowercased())
        newWord = ""
    }
}

private struct RemovableList: View {
    @Binding var items: [String]
    let title: (String) -> String
    let empty: LocalizedStringKey
    let hint: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Text(title(item))
                        Spacer()
                        Button("Remove", systemImage: "minus.circle") {
                            items.removeAll { $0 == item }
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                    }
                }
            }
            .overlay {
                if items.isEmpty { ContentUnavailableView(empty, systemImage: "tray") }
            }
            .clipShape(.rect(cornerRadius: 10))
            Text(hint).font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct AboutView: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text("KeySwitch").font(.title.bold())
            Text("Version \(version)").foregroundStyle(.secondary)
            Text("Keystrokes stay in memory for one word. Nothing is saved or sent.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Link("Source code on GitHub", destination: URL(string: "https://github.com/andrewkomkov/key-switch")!)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
