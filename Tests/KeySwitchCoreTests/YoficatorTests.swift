import Testing
@testable import KeySwitchCore

@Suite struct YoficatorTests {
    static let small = Yoficator(dictionary: """
        Артём(|а|у)
        ещё
        зелён(ая|ый)
        _киёв# a comment
        трёхъярусн(ый|ая)
        """)
    static let full = Yoficator(dictionary: Fixtures.text("Resources/ru-yo.txt"))

    @Test func readsStemsAndEndings() {
        #expect(Self.small.count == 9)
        #expect(Self.small.restore("зеленый") == "зелёный")
        #expect(Self.small.restore("зеленая") == "зелёная")
        #expect(Self.small.restore("зеленое") == "зеленое")
    }

    @Test(arguments: [
        ("еще", "ещё"), ("Еще", "Ещё"), ("ЕЩЕ", "ЕЩЁ"), ("еЩе", "еЩе"),
        ("артем", "артем"), ("Артем", "Артём"), ("АРТЕМУ", "АРТЁМУ"),
        ("киев", "киёв"), ("Киев", "Киев"), ("КИЕВ", "КИЕВ"),
    ])
    func followsTheCaseOfTheTypedWord(typed: String, expected: String) {
        #expect(Self.small.restore(typed) == expected)
    }

    @Test func keepsTheTextAroundTheWords() {
        #expect(Self.small.restore("«Еще, еще!» — и зеленый-зеленый") == "«Ещё, ещё!» — и зелёный-зелёный")
        #expect(Self.small.restore("hello еще1") == "hello ещё1")
        #expect(Self.small.restore("") == "")
    }

    @Test func leavesExceptionsAsTyped() {
        #expect(Self.small.restore("Еще зеленый", exceptions: ["еще"]) == "Еще зелёный")
    }

    @Test func readsTheShippedDictionary() {
        #expect(Self.full.count > 100_000)
    }

    @Test(arguments: [
        ("еще", "ещё"), ("ее", "её"), ("елка", "ёлка"), ("идет", "идёт"), ("черный", "чёрный"),
        ("трехсот", "трёхсот"), ("причем", "причём"), ("Артем", "Артём"),
    ])
    func restoresFrequentWords(typed: String, expected: String) {
        #expect(Self.full.restore(typed) == expected)
    }

    /// In these words `е` can be right, so the dictionary must not have them.
    @Test(arguments: ["все", "нем", "небо", "осел", "передохнем", "берет", "узнаем", "мел", "чем", "лет"])
    func keepsAmbiguousWords(word: String) {
        #expect(Self.full.restore(word) == word)
    }

    @Test func changesFewWordsOfTheFrequencyList() {
        let words = Fixtures.words("Resources/ru.txt", limit: 20_000)
        let changed = words.filter { Self.full.restore($0) != $0 }
        #expect(changed.count > 100)
        #expect(Double(changed.count) / Double(words.count) < 0.05)
    }
}
