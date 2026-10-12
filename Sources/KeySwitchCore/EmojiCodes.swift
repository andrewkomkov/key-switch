/// Emoji codes such as `:fire:`, with the names of GitHub.
public struct EmojiCodes: Sendable {
    private let emoji: [Substring: Substring]

    public var count: Int { emoji.count }

    /// - Parameter list: one line for each code: the name, a tab, the emoji.
    public init(list: String) {
        var emoji: [Substring: Substring] = [:]
        for line in list.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "\t")
            if parts.count == 2 { emoji[parts[0]] = parts[1] }
        }
        self.emoji = emoji
    }

    /// The emoji for a full word of the form `:name:`, or `nil`.
    public func emoji(for typed: String) -> String? {
        guard typed.count > 2, typed.first == ":", typed.last == ":" else { return nil }
        return emoji[typed.dropFirst().dropLast()].map(String.init)
    }
}
