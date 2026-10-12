/// Corrects a word with accidental capitals: `ПРивет` and `пРИВЕТ` become `Привет`.
public enum CaseFixer {
    /// - Parameter isKnown: tells if the word in small letters is a dictionary word.
    /// - Returns: the corrected text, or `nil` if the text must stay as typed.
    public static func fixed(_ text: String, isKnown: (String) -> Bool) -> String? {
        guard let first = text.firstIndex(where: \.isLetter),
              let last = text.lastIndex(where: \.isLetter)
        else { return nil }
        let word = text[first...last]
        guard word.allSatisfy(\.isLetter), isMistake(word), isKnown(word.lowercased()) else { return nil }
        let corrected = word.prefix(1).uppercased() + word.dropFirst().lowercased()
        return text[..<first] + corrected + text[text.index(after: last)...]
    }

    private static func isMistake(_ word: Substring) -> Bool {
        let letters = Array(word)
        guard letters.count >= 3 else { return false }
        if letters[0].isLowercase {
            // `iOS` is correct, so the inverted pattern starts at 4 letters.
            return letters.count >= 4 && letters.dropFirst().allSatisfy(\.isUppercase)
        }
        guard letters[0].isUppercase, letters[1].isUppercase,
              letters.dropFirst(2).allSatisfy(\.isLowercase)
        else { return false }
        // `IDs` and `TVs` are correct plurals.
        return !(letters.count == 3 && letters[2] == "s")
    }
}
