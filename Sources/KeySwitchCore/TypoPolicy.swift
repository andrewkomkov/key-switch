/// Rules for typo correction: which words to examine and which corrections to accept.
/// The correction itself comes from outside, through `suggest`.
public enum TypoPolicy {
    public struct Candidate: Equatable, Sendable {
        public let prefix: String
        public let core: String
        public let suffix: String
    }

    public static let minLength = 3
    public static let maxEdits = 2
    /// A word above this rank is correct. No question goes to the spelling checker.
    public static let frequentRank = 15_000
    /// A rarer word of the list gives way only to a correction this many times more frequent.
    public static let rankRatio = 2

    /// Splits the text into a word and the punctuation around it. `nil` if the word is not
    /// plain enough to correct: a digit, a capital inside, punctuation inside, too short.
    public static func candidate(in text: String) -> Candidate? {
        guard !text.contains(where: \.isNumber),
              let first = text.firstIndex(where: \.isLetter),
              let last = text.lastIndex(where: \.isLetter)
        else { return nil }
        let core = text[first...last]
        guard core.count >= minLength,
              core.allSatisfy(\.isLetter),
              !core.dropFirst().contains(where: \.isUppercase)
        else { return nil }
        return Candidate(
            prefix: String(text[..<first]), core: String(core),
            suffix: String(text[text.index(after: last)...]))
    }

    public static func accepts(_ correction: String, for core: String) -> Bool {
        guard correction.allSatisfy(\.isLetter) else { return false }
        let distance = editDistance(correction.lowercased(), core.lowercased())
        return (1...maxEdits).contains(distance)
    }

    /// The text to show in place of `text`, or `nil` to leave it as typed.
    /// The frequency list has misspellings in it, so only a frequent word counts as correct.
    /// - Parameters:
    ///   - isProtected: a term that must stay as typed, for example `pytest`.
    ///   - suggest: the confident correction of the spelling checker, if it has one.
    public static func correctedText(
        for text: String,
        exceptions: Set<String> = [],
        rank: (String) -> Int?,
        isProtected: (String) -> Bool = { _ in false },
        suggest: (String) -> String?
    ) -> String? {
        guard let candidate = candidate(in: text) else { return nil }
        let core = candidate.core
        let typedRank = rank(core)
        if let typedRank, typedRank < frequentRank { return nil }
        guard !exceptions.contains(Detector.core(of: core)), !isProtected(core),
              let correction = suggest(core), accepts(correction, for: core),
              let correctionRank = rank(correction)
        else { return nil }
        if let typedRank, correctionRank * rankRatio >= typedRank { return nil }
        return candidate.prefix + correction + candidate.suffix
    }

    /// Edit distance where a swap of two adjacent letters is one edit.
    public static func editDistance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        if a.isEmpty || b.isEmpty { return max(a.count, b.count) }
        var rows = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count { rows[i][0] = i }
        for j in 0...b.count { rows[0][j] = j }
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                rows[i][j] = min(rows[i - 1][j] + 1, rows[i][j - 1] + 1, rows[i - 1][j - 1] + cost)
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    rows[i][j] = min(rows[i][j], rows[i - 2][j - 2] + 1)
                }
            }
        }
        return rows[a.count][b.count]
    }
}
