import Foundation
import Testing
import KeySwitchCore

@Suite struct ClipboardHistoryTests {
    private func text(_ string: String) -> ClipboardEntry {
        ClipboardEntry(content: .text(string))
    }

    private func image(_ digest: String, file: String = "a.png") -> ClipboardEntry {
        ClipboardEntry(content: .image(file: file, width: 2, height: 1, digest: digest))
    }

    private func texts(_ history: ClipboardHistory) -> [String] {
        history.entries.map { if case .text(let string) = $0.content { string } else { "image" } }
    }

    @Test func newestIsFirst() {
        var history = ClipboardHistory()
        for word in ["alpha", "beta", "gamma"] { _ = history.insert(text(word)) }
        #expect(texts(history) == ["gamma", "beta", "alpha"])
    }

    @Test func aSecondCopyReplacesTheFirst() {
        var history = ClipboardHistory()
        let first = text("alpha")
        _ = history.insert(first)
        _ = history.insert(text("beta"))
        let dropped = history.insert(text("alpha"))
        #expect(texts(history) == ["alpha", "beta"])
        #expect(dropped == [first])
    }

    @Test func imagesAreComparedByTheirData() {
        var history = ClipboardHistory()
        let first = image("abc", file: "1.png")
        _ = history.insert(first)
        #expect(history.entry(matching: image("abc", file: "2.png").content) == first)
        #expect(history.entry(matching: image("def").content) == nil)
        #expect(history.entry(matching: .text("abc")) == nil)
    }

    @Test func theLimitDropsTheOldest() {
        var history = ClipboardHistory(limit: 2)
        let oldest = text("alpha")
        _ = history.insert(oldest)
        _ = history.insert(text("beta"))
        let dropped = history.insert(text("gamma"))
        #expect(texts(history) == ["gamma", "beta"])
        #expect(dropped == [oldest])
    }

    @Test func aSmallerLimitReturnsWhatLeft() {
        var history = ClipboardHistory()
        for word in ["alpha", "beta", "gamma"] { _ = history.insert(text(word)) }
        let dropped = history.setLimit(1)
        #expect(texts(history) == ["gamma"])
        #expect(dropped.count == 2)
        #expect(history.setLimit(0).isEmpty)
        #expect(history.limit == 1)
    }

    @Test func touchMovesAnEntryToTheTop() {
        var history = ClipboardHistory()
        let alpha = text("alpha")
        _ = history.insert(alpha)
        _ = history.insert(text("beta"))
        history.touch(alpha.id, date: Date(timeIntervalSince1970: 5))
        #expect(texts(history) == ["alpha", "beta"])
        #expect(history.entries[0].date == Date(timeIntervalSince1970: 5))
        history.touch(UUID())
        #expect(history.entries.count == 2)
    }

    @Test func removeAndClear() {
        var history = ClipboardHistory()
        let alpha = text("alpha")
        _ = history.insert(alpha)
        _ = history.insert(image("abc"))
        #expect(history.remove(alpha.id) == alpha)
        #expect(history.remove(alpha.id) == nil)
        #expect(history.clear().count == 1)
        #expect(history.entries.isEmpty)
    }

    @Test func entriesSurviveJSON() throws {
        let entries = [text("привет\nмир"), image("abc")]
        let data = try JSONEncoder().encode(entries)
        let decoded = try JSONDecoder().decode([ClipboardEntry].self, from: data)
        #expect(decoded == entries)
        #expect(ClipboardHistory(entries: decoded, limit: 1).entries == [entries[0]])
    }

    @Test func aPinnedEntryStaysAtTheLimit() {
        var history = ClipboardHistory(limit: 2)
        let alpha = text("alpha")
        _ = history.insert(alpha)
        #expect(history.setPinned(true, for: alpha.id).isEmpty)
        for word in ["beta", "gamma", "delta"] { _ = history.insert(text(word)) }
        #expect(texts(history) == ["delta", "gamma", "alpha"])
        #expect(history.pinned.map(\.id) == [alpha.id])
        #expect(history.recent.count == 2)
    }

    @Test func clearKeepsThePinnedEntries() {
        var history = ClipboardHistory()
        let alpha = text("alpha")
        _ = history.insert(alpha)
        _ = history.insert(text("beta"))
        _ = history.setPinned(true, for: alpha.id)
        #expect(history.clear().count == 1)
        #expect(texts(history) == ["alpha"])
        #expect(history.remove(alpha.id)?.pinned == true)
    }

    @Test func aSecondCopyKeepsThePin() {
        var history = ClipboardHistory()
        let alpha = text("alpha")
        _ = history.insert(alpha)
        _ = history.setPinned(true, for: alpha.id)
        _ = history.insert(text("beta"))
        #expect(history.insert(text("alpha")).map(\.id) == [alpha.id])
        #expect(texts(history) == ["alpha", "beta"])
        #expect(history.entries[0].pinned)
    }

    @Test func withoutItsPinAnEntryCountsForTheLimit() {
        var history = ClipboardHistory(limit: 1)
        let alpha = text("alpha")
        _ = history.insert(alpha)
        _ = history.setPinned(true, for: alpha.id)
        _ = history.insert(text("beta"))
        #expect(history.setPinned(false, for: alpha.id).map(\.id) == [alpha.id])
        #expect(texts(history) == ["beta"])
        #expect(history.setPinned(true, for: UUID()).isEmpty)
    }

    @Test func anOldFileHasNoPins() throws {
        let old = #"[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","date":0,"content":{"text":{"_0":"alpha"}}}]"#
        let decoded = try JSONDecoder().decode([ClipboardEntry].self, from: Data(old.utf8))
        #expect(decoded.map(\.pinned) == [false])
        var pinned = decoded[0]
        pinned.pinned = true
        let again = try JSONDecoder().decode(ClipboardEntry.self, from: JSONEncoder().encode(pinned))
        #expect(again == pinned)
    }

    @Test func searchFindsEachWordOfTheQuery() {
        var history = ClipboardHistory()
        for word in ["Невский проспект, 28", "nevsky prospect", "Café Zürich"] { _ = history.insert(text(word)) }
        _ = history.insert(image("abc"))
        let pinned = text("pinned note")
        _ = history.insert(pinned)
        _ = history.insert(text("newest"))
        _ = history.setPinned(true, for: pinned.id)

        func found(_ query: String) -> [String] { texts(ClipboardHistory(entries: history.search(query), limit: 100)) }
        #expect(found("") == ["pinned note", "newest", "image", "Café Zürich", "nevsky prospect", "Невский проспект, 28"])
        #expect(found("  ") == found(""))
        #expect(found("НЕВСК") == ["Невский проспект, 28"])
        #expect(found("28 невский") == ["Невский проспект, 28"])
        #expect(found("cafe zurich") == ["Café Zürich"])
        #expect(found("ne") == ["pinned note", "newest", "nevsky prospect"])
        #expect(found("nevsky 28").isEmpty)
        #expect(found("image").isEmpty)
    }

    @Test(arguments: [
        ("hello", "hello"),
        ("  two\n\n  lines\t here ", "two lines here"),
        (String(repeating: "a", count: 80), String(repeating: "a", count: 59) + "…"),
        ("", ""),
    ])
    func titleIsOneShortLine(text: String, expected: String) {
        #expect(ClipboardHistory.title(for: text) == expected)
    }
}
