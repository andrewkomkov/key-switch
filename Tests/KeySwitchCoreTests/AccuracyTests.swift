import Foundation
import Testing
import KeySwitchCore

/// Measures the detector on words it has in the dictionary and on held-out words it has
/// never seen. The limits are the success criteria of specs/001-layout-switcher/spec.md.
@Suite struct AccuracyTests {
    let detector = Fixtures.detector

    struct Language: Sendable, CustomStringConvertible {
        let code: String
        let other: String
        /// What a word of this language looks like when typed on the other layout.
        let mistype: @Sendable (String) -> String
        var description: String { code }
    }

    static let languages = [
        Language(code: "ru", other: "en", mistype: Keyboard.asLatin),
        Language(code: "en", other: "ru", mistype: Keyboard.asCyrillic),
    ]

    func rate(_ words: [String], _ converts: (String) -> Bool) -> Double {
        let words = words.filter { $0.count > 1 }
        return Double(words.count { converts($0) }) / Double(words.count)
    }

    /// Share of wrongly typed words that the detector fixes.
    func recall(_ words: [String], _ language: Language) -> Double {
        rate(words) { word in
            detector.shouldConvert(
                current: language.mistype(word), language: language.other,
                other: word, otherLanguage: language.code)
        }
    }

    /// Share of correctly typed words that the detector breaks.
    func falsePositives(_ words: [String], _ language: Language) -> Double {
        rate(words) { word in
            detector.shouldConvert(
                current: word, language: language.code,
                other: language.mistype(word), otherLanguage: language.other)
        }
    }

    @Test(arguments: languages)
    func frequentWordsAreFixed(_ language: Language) {
        let value = recall(Fixtures.words("Resources/\(language.code).txt", limit: 20_000), language)
        print("recall, top 20000 \(language): \(value)")
        #expect(value >= 0.95)
    }

    @Test(arguments: languages)
    func frequentWordsAreNotBroken(_ language: Language) {
        let words = Fixtures.words("Resources/\(language.code).txt", limit: 20_000)
        #expect(falsePositives(Array(words.prefix(8000)), language) == 0)
        let value = falsePositives(words, language)
        print("false positives, top 20000 \(language): \(value)")
        #expect(value < 0.001)
    }

    @Test(arguments: languages)
    func unknownWordsAreRarelyBroken(_ language: Language) {
        let value = falsePositives(Fixtures.words("Tests/KeySwitchCoreTests/Fixtures/\(language.code)-heldout.txt"), language)
        print("false positives, held-out \(language): \(value)")
        #expect(value < 0.005)
    }

    @Test(arguments: languages)
    func unknownWordsAreMostlyFixed(_ language: Language) {
        let value = recall(Fixtures.words("Tests/KeySwitchCoreTests/Fixtures/\(language.code)-heldout.txt"), language)
        print("recall, held-out \(language): \(value)")
        #expect(value >= 0.90)
    }

    @Test func decisionIsFast() {
        let words = Fixtures.words("Tests/KeySwitchCoreTests/Fixtures/ru-heldout.txt")
        let pairs = words.map { (Keyboard.asLatin($0), $0) }
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for (typed, wanted) in pairs {
                _ = detector.shouldConvert(current: typed, language: "en", other: wanted, otherLanguage: "ru")
            }
        }
        let microseconds = Double(elapsed.components.attoseconds) / 1e12 / Double(pairs.count)
            + Double(elapsed.components.seconds) * 1e6 / Double(pairs.count)
        print("microseconds per word: \(microseconds)")
        #expect(microseconds < 50)
    }
}
