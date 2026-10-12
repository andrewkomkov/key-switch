import AppKit
import KeySwitchCore
import Observation
import SwiftUI

/// A floating panel that searches the clipboard history and pastes the selected entry
/// into the front app. The panel takes the keys, but the front app stays active.
@MainActor
@Observable
final class ClipboardSearch {
    static let shared = ClipboardSearch()

    var query = "" { didSet { selection = results.first?.id } }
    var selection: ClipboardEntry.ID?
    private(set) var isVisible = false

    var results: [ClipboardEntry] { monitor.history.search(query) }

    @ObservationIgnored private let monitor = ClipboardMonitor.shared
    @ObservationIgnored private var panel: Panel?
    @ObservationIgnored private var closeObserver: (any NSObjectProtocol)?

    private init() {}

    func show() {
        guard !isVisible else { return }
        let panel = panel ?? makePanel()
        self.panel = panel
        query = ""
        selection = results.first?.id
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame, size = panel.frame.size
            panel.setFrameOrigin(NSPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2 + frame.height / 8))
        }
        isVisible = true
        panel.makeKeyAndOrderFront(nil)
    }

    /// Closes the panel with no change to the clipboard.
    func close() {
        guard isVisible else { return }
        isVisible = false
        panel?.orderOut(nil)
    }

    func moveSelection(by step: Int) {
        let results = results
        guard !results.isEmpty else { return }
        let index = results.firstIndex { $0.id == selection } ?? -step
        selection = results[min(max(index + step, 0), results.count - 1)].id
    }

    /// Puts the selected entry in the clipboard and pastes it into the front app.
    func pasteSelection() {
        guard let entry = results.first(where: { $0.id == selection }) else { return }
        paste(entry)
    }

    func paste(_ entry: ClipboardEntry) {
        close()
        monitor.select(entry)
        Task {
            // The front app must have the keys again before the paste.
            try? await Task.sleep(for: .milliseconds(150))
            Typist.press(9, flags: .maskCommand)
        }
    }

    private func makePanel() -> Panel {
        let panel = Panel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 380),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView], backing: .buffered, defer: false)
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: ClipboardSearchView(search: self, monitor: monitor))
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: panel, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.close() }
        }
        return panel
    }

    /// A panel without a title bar does not become key by default.
    private final class Panel: NSPanel {
        override var canBecomeKey: Bool { true }

        override func cancelOperation(_ sender: Any?) {
            ClipboardSearch.shared.close()
        }
    }
}

private struct ClipboardSearchView: View {
    @Bindable var search: ClipboardSearch
    let monitor: ClipboardMonitor
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search the clipboard history", text: $search.query)
                .textFieldStyle(.plain)
                .font(.title2)
                .padding()
                .focused($isFocused)
                .onSubmit(search.pasteSelection)
                .onKeyPress(.downArrow) { search.moveSelection(by: 1); return .handled }
                .onKeyPress(.upArrow) { search.moveSelection(by: -1); return .handled }
                .onKeyPress(.escape) { search.close(); return .handled }
            Divider()
            ScrollViewReader { proxy in
                List(search.results, selection: $search.selection) { entry in
                    HStack {
                        ClipboardEntryLabel(entry: entry, clipboard: monitor)
                            .lineLimit(1)
                        Spacer()
                        if entry.pinned { Image(systemName: "pin.fill").foregroundStyle(.secondary) }
                    }
                    .contentShape(.rect)
                    .onTapGesture { search.paste(entry) }
                    .id(entry.id)
                }
                .onChange(of: search.selection) { _, selected in
                    if let selected { proxy.scrollTo(selected) }
                }
            }
            .overlay {
                if search.results.isEmpty { ContentUnavailableView("Nothing found", systemImage: "magnifyingglass") }
            }
        }
        .onChange(of: search.isVisible, initial: true) { _, visible in
            if visible { isFocused = true }
        }
    }
}
