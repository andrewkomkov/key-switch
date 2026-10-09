import Testing
import KeySwitchCore

@Suite struct WordLearnerTests {
    @Test func learnsOnTheThirdUse() {
        var learner = WordLearner()
        var results: [Bool] = []
        for _ in 0..<4 { results.append(learner.observe("гит", language: "ru")) }
        #expect(results == [false, false, true, false])
    }

    @Test func languagesAreCountedApart() {
        var learner = WordLearner()
        _ = learner.observe("git", language: "en")
        _ = learner.observe("git", language: "en")
        let other = learner.observe("git", language: "ru")
        #expect(!other)
    }

    @Test func forgetStartsTheCountAgain() {
        var learner = WordLearner()
        _ = learner.observe("гит", language: "ru")
        _ = learner.observe("гит", language: "ru")
        learner.forget("гит", language: "ru")
        let learned = learner.observe("гит", language: "ru")
        #expect(!learned)
    }

    @Test func aLearnedWordIsConvertedLikeADictionaryWord() {
        var detector = Fixtures.detector
        #expect(!detector.shouldConvert(current: "ubn", language: "en", other: "гит", otherLanguage: "ru"))
        #expect(!detector.shouldConvert(current: "fghed", language: "en", other: "апрув", otherLanguage: "ru"))
        detector.learned = ["ru": ["гит", "апрув"]]
        #expect(detector.shouldConvert(current: "ubn", language: "en", other: "гит", otherLanguage: "ru"))
        #expect(detector.shouldConvert(current: "Fghed,", language: "en", other: "Апрувб", otherLanguage: "ru") == false)
        #expect(detector.shouldConvert(current: "fghed", language: "en", other: "апрув", otherLanguage: "ru"))
        #expect(!detector.shouldConvert(current: "гит", language: "ru", other: "ubn", otherLanguage: "en"))
        #expect(detector.rank(of: "гит", language: "ru") == Detector.learnedRank)
    }

    func learnableAsRussian(_ word: String) -> Bool {
        Fixtures.detector.isLearnable(word, language: "ru", other: Keyboard.asLatin(word), otherLanguage: "en")
    }

    func learnableAsEnglish(_ word: String) -> Bool {
        Fixtures.detector.isLearnable(word, language: "en", other: Keyboard.asCyrillic(word), otherLanguage: "ru")
    }

    @Test(arguments: ["гит", "апрув", "кек", "гитхаб", "бэкенд", "пулреквест"])
    func russianWorkWordsCanBeLearned(_ word: String) {
        #expect(learnableAsRussian(word))
    }

    @Test(arguments: ["привет", "аб", "git", "руддщ", "цщкдв", ""])
    func theseCannotBeLearnedAsRussian(_ word: String) {
        #expect(!learnableAsRussian(word))
    }

    @Test(arguments: ["kubectl", "pnpm", "xcrun"])
    func englishWorkWordsCanBeLearned(_ word: String) {
        var detector = Detector(models: [
            .russian(wordList: Fixtures.text("Resources/ru.txt")),
            .english(wordList: Fixtures.text("Resources/en.txt")),
        ])
        detector.learned = [:]
        #expect(detector.isLearnable(word, language: "en", other: Keyboard.asCyrillic(word), otherLanguage: "ru"))
    }

    @Test(arguments: ["hello", "ghbdtn", "rfr", "ntcn", "xnj", "plhfdcndeqnt", "h2o"])
    func theseCannotBeLearnedAsEnglish(_ word: String) {
        #expect(!learnableAsEnglish(word))
    }

    @Test func aManualConversionTeachesAndAConversionBackDoesNot() {
        var detector = Fixtures.detector
        #expect(detector.isLearnable("гитхаб", language: "ru", other: "ubn[f,", otherLanguage: "en", confirmed: true))
        detector.learned = ["ru": ["апрув"]]
        #expect(!detector.isLearnable("fghed", language: "en", other: "апрув", otherLanguage: "ru", confirmed: true))
        #expect(!detector.isLearnable("ghbdtn", language: "en", other: "привет", otherLanguage: "ru", confirmed: true))
    }
}
