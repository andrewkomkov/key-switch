import AppKit
import Testing
import KeySwitchCore

@Suite struct TypoPolicyTests {
    @Test func splitsThePunctuationFromTheWord() {
        let candidate = TypoPolicy.candidate(in: "(Recieve,")
        #expect(candidate?.prefix == "(")
        #expect(candidate?.core == "Recieve")
        #expect(candidate?.suffix == ",")
    }

    @Test(arguments: ["ok", "h2o", "iPhone", "README", "file.txt", "don't", "...", "", "a-b"])
    func wordsThatAreNotExamined(_ text: String) {
        #expect(TypoPolicy.candidate(in: text) == nil)
    }

    @Test(arguments: [("teh", "the", 1), ("recieve", "receive", 1), ("севодня", "сегодня", 1),
                      ("агенство", "агентство", 1), ("cat", "cat", 0), ("kitten", "sitting", 3), ("", "abc", 3)])
    func editDistance(_ a: String, _ b: String, _ expected: Int) {
        #expect(TypoPolicy.editDistance(a, b) == expected)
        #expect(TypoPolicy.editDistance(b, a) == expected)
    }

    @Test func acceptsOnlyACloseSingleWord() {
        #expect(TypoPolicy.accepts("receive", for: "recieve"))
        #expect(!TypoPolicy.accepts("English", for: "english"))
        #expect(!TypoPolicy.accepts("a lot", for: "alot"))
        #expect(!TypoPolicy.accepts("sitting", for: "kitten"))
    }

    let ranks = ["receive": 1000, "recieve": 40_000, "the": 0, "purest": 30_000, "untill": 20_000, "until": 12_000]

    func corrected(_ text: String, exceptions: Set<String> = [], suggestion: String?) -> String? {
        TypoPolicy.correctedText(
            for: text, exceptions: exceptions, rank: { ranks[$0.lowercased()] },
            isProtected: { $0 == "pytest" }, suggest: { _ in suggestion })
    }

    @Test func keepsThePunctuationAndTheCapital() {
        #expect(corrected("(Recieve,", suggestion: "Receive") == "(Receive,")
    }

    @Test func skipsExceptionsAndProtectedWords() {
        #expect(corrected("recieve", exceptions: ["recieve"], suggestion: "receive") == nil)
        #expect(corrected("pytest", suggestion: "purest") == nil)
    }

    @Test func theCorrectionMustBeAWordOfTheList() {
        #expect(corrected("recieve", suggestion: "recieved") == nil)
    }

    @Test func aListedWordGivesWayOnlyToAMuchMoreFrequentOne() {
        #expect(corrected("recieve", suggestion: "receive") == "receive")
        #expect(corrected("untill", suggestion: "until") == nil)
    }

    @Test func aFrequentWordCostsNoCallToTheChecker() {
        var calls = 0
        let detector = Fixtures.detector
        for word in ["hello", "world", "the"] {
            _ = TypoPolicy.correctedText(
                for: word, rank: { detector.rank(of: $0, language: "en") },
                suggest: { _ in calls += 1; return nil })
        }
        #expect(calls == 0)
    }
}

/// Checks the rules against the real macOS spelling checker.
/// Its dictionary changes with the macOS version: keep here only the words that all versions agree on.
@MainActor
@Suite(.enabled(if: NSSpellChecker.shared.availableLanguages.contains("en")
                  && NSSpellChecker.shared.availableLanguages.contains("ru")))
struct SystemSpellCheckerTests {
    static let tag = NSSpellChecker.uniqueSpellDocumentTag()

    func corrected(_ text: String, language: String) -> String? {
        let detector = Fixtures.detector
        return TypoPolicy.correctedText(
            for: text,
            rank: { detector.rank(of: $0, language: language) },
            isProtected: { Fixtures.technicalWords.contains($0.lowercased()) },
            suggest: { word in
                NSSpellChecker.shared.correction(
                    forWordRange: NSRange(location: 0, length: (word as NSString).length),
                    in: word, language: language, inSpellDocumentWithTag: Self.tag)
            })
    }

    @Test(arguments: [("recieve", "receive"), ("definately", "definitely"), ("Wierd,", "Weird,"), ("seperate", "separate"), ("untill", "until")])
    func englishTypos(_ typed: String, _ expected: String) {
        #expect(corrected(typed, language: "en") == expected)
    }

    @Test(arguments: [("севодня", "сегодня"), ("здраствуйте", "здравствуйте"), ("сдесь", "здесь"), ("зделать", "сделать")])
    func russianTypos(_ typed: String, _ expected: String) {
        #expect(corrected(typed, language: "ru") == expected)
    }

    @Test(arguments: [
        "kubectl", "nginx", "pytest", "localhost", "github", "dockerfile", "webpack", "eslint", "tsconfig",
        "println", "stderr", "malloc", "typedef", "nullptr", "golang", "kotlin", "swiftui", "homebrew",
        "tmux", "nvim", "pycharm", "numpy", "pytorch", "clickhouse", "bigquery", "README", "iPhone",
        "Komkov", "h2o", "ok", "xqzt", "lgtm",
    ])
    func technicalWordsStayAsTyped(_ word: String) {
        #expect(corrected(word, language: "en") == nil)
    }

    @Test(arguments: ["кубернетес", "гитхаб", "пайтон", "Комков", "щас", "норм", "спс", "докер", "фронтенд", "бэкенд"])
    func russianSlangStaysAsTyped(_ word: String) {
        #expect(corrected(word, language: "ru") == nil)
    }
}
