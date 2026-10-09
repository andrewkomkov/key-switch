import AppKit

/// The macOS spelling checker, asked only for the correction it would apply by itself.
@MainActor
enum SpellCorrector {
    private static let tag = NSSpellChecker.uniqueSpellDocumentTag()

    static func correction(for word: String, language: String) -> String? {
        let checker = NSSpellChecker.shared
        guard checker.availableLanguages.contains(language) else { return nil }
        return checker.correction(
            forWordRange: NSRange(location: 0, length: (word as NSString).length),
            in: word, language: language, inSpellDocumentWithTag: tag)
    }
}
