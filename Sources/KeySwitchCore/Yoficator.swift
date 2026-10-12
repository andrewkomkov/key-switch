/// Puts the letter `ё` back into Russian words that were typed with `е`.
/// The dictionary has only the words where `е` in that place is always `ё`.
public struct Yoficator: Sendable {
    /// Lowercase spelling with `е` to the spelling with `ё`.
    private var common: [String: String] = [:]
    /// Names: they get `ё` only when the typed word starts with a capital.
    private var proper: [String: String] = [:]
    /// Words that get `ё` only when the typed word is in small letters.
    private var lowercaseOnly: Set<String> = []

    public var count: Int { common.count + proper.count }

    /// - Parameter dictionary: one entry per line, as `stem(ending|ending)` or a full word.
    ///   A `#` starts a comment. A leading `_` marks a word for small letters only.
    public init(dictionary: String) {
        for line in dictionary.split(whereSeparator: \.isNewline) {
            let entry = line.prefix { $0 != "#" }.filter { !$0.isWhitespace }
            guard let open = entry.firstIndex(of: "(") else {
                add(String(entry))
                continue
            }
            let stem = entry[..<open]
            let endings = entry[entry.index(after: open)...].prefix { $0 != ")" }
            for ending in endings.split(separator: "|", omittingEmptySubsequences: false) {
                add(String(stem) + ending)
            }
        }
    }

    /// The text with `ё` in each known word. The length of the text stays the same.
    /// - Parameter exceptions: lowercase words with `е` that must stay as typed.
    public func restore(_ text: String, exceptions: Set<String> = []) -> String {
        guard text.contains(where: { $0 == "е" || $0 == "Е" }) else { return text }
        var result = "", word = ""
        for character in text {
            if character.isLetter {
                word.append(character)
            } else {
                result += restored(word, exceptions) + String(character)
                word = ""
            }
        }
        return result + restored(word, exceptions)
    }

    private func restored(_ word: String, _ exceptions: Set<String>) -> String {
        let lower = word.lowercased()
        guard lower.contains("е"), !exceptions.contains(lower) else { return word }
        let rest = word.dropFirst()
        let isLower = word == lower
        // `Еще` and `ЕЩЕ` are fine, `еЩе` is not a spelling that the dictionary knows.
        guard isLower || rest == rest.lowercased() || word == word.uppercased() else { return word }

        let pattern: String
        if isLower {
            guard let known = common[lower] else { return word }
            pattern = known
        } else if let known = common[lower], !lowercaseOnly.contains(lower) {
            pattern = known
        } else if let known = proper[lower] {
            pattern = known
        } else {
            return word
        }
        guard pattern.count == word.count else { return word }
        return String(zip(word, pattern).map { typed, known -> Character in
            guard known == "ё" else { return typed }
            return typed.isUppercase ? "Ё" : "ё"
        })
    }

    private mutating func add(_ entry: String) {
        var word = entry
        let onlyLower = word.hasPrefix("_")
        if onlyLower { word.removeFirst() }
        guard !word.isEmpty else { return }
        let lower = word.lowercased()
        let key = lower.replacing("ё", with: "е")
        if word.first?.isUppercase == true {
            proper[key] = lower
        } else {
            common[key] = lower
            if onlyLower { lowercaseOnly.insert(key) }
        }
    }
}
