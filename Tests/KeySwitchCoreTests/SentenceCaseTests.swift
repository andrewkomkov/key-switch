import Testing
import KeySwitchCore

@Suite struct SentenceCaseTests {
    @Test(arguments: [
        ("как", "Привет.", "Как"),
        ("hello", "world!", "Hello"),
        ("really", "what?", "Really"),
        ("да,", "Нет?!", "Да,"),
        ("«привет»", "сказал.", "«Привет»"),
        ("well-known", "end.)", "Well-known"),
        ("потом", "2020.", "Потом"),
        ("ёлка", "вот.", "Ёлка"),
    ])
    func theFirstWordOfASentenceGetsACapital(word: String, previous: String, expected: String) {
        #expect(SentenceCase.capitalized(word, after: previous) == expected)
    }

    @Test(arguments: [
        ("как", "Привет"),
        ("как", "Привет,"),
        ("как", ""),
        ("как", "."),
        ("как", "ну..."),
        ("как", "т.е."),
        ("example", "e.g."),
        ("something", "etc."),
        ("москва", "г."),
        ("пушкин", "А."),
        ("status", ".."),
        ("Как", "Привет."),
        ("iPhone", "Привет."),
        ("v2", "Привет."),
        ("readme.md", "See."),
        ("user@example.com", "Mail."),
        ("123", "Привет."),
        ("...", "Привет."),
        ("", "Привет."),
    ])
    func otherWordsStay(word: String, previous: String) {
        #expect(SentenceCase.capitalized(word, after: previous) == nil)
    }
}
