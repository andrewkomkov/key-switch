import Foundation

/// One copied item.
public struct ClipboardEntry: Codable, Identifiable, Equatable, Sendable {
    public enum Content: Codable, Equatable, Sendable {
        case text(String)
        /// - Parameter digest: a hash of the image data, to find a second copy of the image.
        case image(file: String, width: Int, height: Int, digest: String)

        /// The same text, or the same image data.
        public func matches(_ other: Content) -> Bool {
            switch (self, other) {
            case (.text(let a), .text(let b)): a == b
            case (.image(_, _, _, let a), .image(_, _, _, let b)): a == b
            default: false
            }
        }
    }

    public let id: UUID
    public var date: Date
    public var content: Content
    /// The limit and the clear function leave a pinned entry alone.
    public var pinned: Bool

    public init(id: UUID = UUID(), date: Date = Date(), content: Content, pinned: Bool = false) {
        self.id = id
        self.date = date
        self.content = content
        self.pinned = pinned
    }

    /// A file of version 0.5.0 has no `pinned` field.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        date = try values.decode(Date.self, forKey: .date)
        content = try values.decode(Content.self, forKey: .content)
        pinned = try values.decodeIfPresent(Bool.self, forKey: .pinned) ?? false
    }
}

/// What the user copied, the newest first. Each content is there one time.
/// The limit counts only the entries without a pin.
public struct ClipboardHistory: Equatable, Sendable {
    public static let limits = [10, 25, 50, 100]
    public static let defaultLimit = 25
    public static let maxTextLength = 200_000

    public private(set) var entries: [ClipboardEntry]
    public private(set) var limit: Int

    public init(entries: [ClipboardEntry] = [], limit: Int = defaultLimit) {
        self.limit = max(1, limit)
        self.entries = entries
        _ = trim()
    }

    public var pinned: [ClipboardEntry] { entries.filter(\.pinned) }
    public var recent: [ClipboardEntry] { entries.filter { !$0.pinned } }

    public func entry(matching content: ClipboardEntry.Content) -> ClipboardEntry? {
        entries.first { $0.content.matches(content) }
    }

    /// Puts the entry on top. A pinned entry with the same content gives its pin to it.
    /// Returns the entries that left the history.
    public mutating func insert(_ entry: ClipboardEntry) -> [ClipboardEntry] {
        let same = entries.filter { $0.content.matches(entry.content) }
        entries.removeAll { $0.content.matches(entry.content) }
        var entry = entry
        entry.pinned = entry.pinned || same.contains(where: \.pinned)
        entries.insert(entry, at: 0)
        return same + trim()
    }

    /// Returns the entries that left the history: without its pin, an entry counts for the limit.
    public mutating func setPinned(_ pinned: Bool, for id: UUID) -> [ClipboardEntry] {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return [] }
        entries[index].pinned = pinned
        return trim()
    }

    /// Moves a known entry to the top, as the newest one.
    public mutating func touch(_ id: UUID, date: Date = Date()) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        var entry = entries.remove(at: index)
        entry.date = date
        entries.insert(entry, at: 0)
    }

    public mutating func remove(_ id: UUID) -> ClipboardEntry? {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return nil }
        return entries.remove(at: index)
    }

    /// Removes the entries without a pin and returns them.
    public mutating func clear() -> [ClipboardEntry] {
        defer { entries = pinned }
        return recent
    }

    /// Returns the entries that left the history.
    public mutating func setLimit(_ limit: Int) -> [ClipboardEntry] {
        self.limit = max(1, limit)
        return trim()
    }

    private mutating func trim() -> [ClipboardEntry] {
        let dropped = Array(recent.dropFirst(limit))
        if !dropped.isEmpty {
            let ids = Set(dropped.map(\.id))
            entries.removeAll { ids.contains($0.id) }
        }
        return dropped
    }

    /// One line for a menu: no line breaks, no long runs of spaces, a limited length.
    public static func title(for text: String, maxLength: Int = 60) -> String {
        let words = text.split(whereSeparator: \.isWhitespace)
        let line = words.joined(separator: " ")
        return line.count > maxLength ? line.prefix(maxLength - 1) + "…" : line
    }
}
