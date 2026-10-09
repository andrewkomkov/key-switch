/// Changes the letter case of a text: lower, then Capitalized, then UPPER, then lower again.
/// A text typed with Caps Lock on by mistake (`hELLO wORLD`) gets its case inverted.
public enum CaseCycler {
    public static func next(_ text: String) -> String {
        let letters = text.filter(\.isLetter)
        guard let first = letters.first else { return text }
        let rest = letters.dropFirst()

        if letters.allSatisfy(\.isLowercase) { return capitalized(text) }
        if letters.allSatisfy(\.isUppercase) { return text.lowercased() }
        if isCapsLockMistake(text) {
            return String(text.map { Character($0.isUppercase ? $0.lowercased() : $0.uppercased()) })
        }
        if first.isUppercase, rest.allSatisfy(\.isLowercase) { return text.uppercased() }
        return text.lowercased()
    }

    private static func capitalized(_ text: String) -> String {
        guard let index = text.firstIndex(where: \.isLetter) else { return text }
        return text.replacingCharacters(in: index...index, with: text[index].uppercased())
    }

    /// Every word starts with a small letter and goes on in capitals.
    private static func isCapsLockMistake(_ text: String) -> Bool {
        let words = text.split(whereSeparator: { !$0.isLetter })
        return words.contains { $0.count > 1 } && words.allSatisfy { word in
            word.first!.isLowercase && word.dropFirst().allSatisfy(\.isUppercase)
        }
    }
}
