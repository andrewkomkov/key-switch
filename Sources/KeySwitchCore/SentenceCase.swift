/// Gives a capital to the first word of a sentence.
public enum SentenceCase {
    /// Words that have a full stop after them in the middle of a sentence.
    private static let abbreviations: Set<String> = [
        "др", "пр", "см", "ср", "стр", "рис", "табл", "гл", "ул", "пл", "просп", "пер", "тел", "руб",
        "коп", "тыс", "млн", "млрд", "им", "напр", "etc", "vs", "mr", "mrs", "ms", "dr", "prof", "st",
        "no", "inc", "ltd", "co", "fig", "approx", "est", "min", "max", "jr", "sr",
    ]
    private static let opening: Set<Character> = ["(", "[", "\"", "'", "«", "“"]
    private static let closing: Set<Character> = [")", "]", "\"", "'", "»", "”"]
    private static let marks: Set<Character> = [".", ",", "!", "?", ";", ":"]

    /// - Parameters:
    ///   - word: the completed word, with possible punctuation at its two ends.
    ///   - previous: the word before it in the same phrase.
    /// - Returns: the word with a capital first letter, or `nil` if it must stay as typed.
    public static func capitalized(_ word: String, after previous: String) -> String? {
        guard endsSentence(previous),
              let first = word.firstIndex(where: { !opening.contains($0) }),
              let last = word.lastIndex(where: { !marks.contains($0) && !closing.contains($0) }), first <= last
        else { return nil }
        let core = word[first...last]
        guard core.allSatisfy({ ($0.isLetter && $0.isLowercase) || $0 == "-" }), word[first].isLetter else { return nil }
        let capital = word[first].uppercased()
        guard capital.count == 1 else { return nil }
        return word[..<first] + capital + word[word.index(after: first)...]
    }

    private static func endsSentence(_ previous: String) -> Bool {
        var text = Substring(previous)
        while let last = text.last, closing.contains(last) { text.removeLast() }
        guard let mark = text.last, mark == "." || mark == "!" || mark == "?" else { return false }
        let body = text.dropLast()
        guard let end = body.last else { return false }
        if mark != "." { return true }
        // An ellipsis goes on with the sentence. A word of one letter is an initial or
        // `т.`, and a word with a full stop in it is an abbreviation such as `e.g.`.
        guard end != ".", body.count > 1, !body.contains(".") else { return false }
        return !abbreviations.contains(body.lowercased())
    }
}
