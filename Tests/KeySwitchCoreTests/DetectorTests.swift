import Foundation
import Testing
import KeySwitchCore

@Suite struct DetectorTests {
    let detector = Fixtures.detector

    /// The user wanted Russian and typed on the English layout.
    func convertsToRussian(_ typed: String, exceptions: Set<String> = []) -> Bool {
        detector.shouldConvert(
            current: typed, language: "en",
            other: Keyboard.asCyrillic(typed), otherLanguage: "ru",
            exceptions: exceptions)
    }

    /// The user wanted English and typed on the Russian layout.
    func convertsToEnglish(_ typed: String) -> Bool {
        detector.shouldConvert(
            current: typed, language: "ru",
            other: Keyboard.asLatin(typed), otherLanguage: "en")
    }

    @Test(arguments: ["ghbdtn", "Ghbdtn", "vbh", "yt", "k.,k.", ";bpym", "[jhjij", "xnj-nj", "ghbdtn?"])
    func russianOnEnglishLayout(_ typed: String) {
        #expect(convertsToRussian(typed))
    }

    @Test(arguments: ["руддщ", "Руддщ", "цщкдв", "еру", "вщтэе", "руддщб", "ашду"])
    func englishOnRussianLayout(_ typed: String) {
        #expect(convertsToEnglish(typed))
    }

    @Test(arguments: [
        "hello", "the", "a", "I", "ok", "kubectl", "nginx", "pytest", "localhost", "github",
        "file.txt", "user@example.com", "http", "https", "mysql", "vs.", "README", "SQL", "x", "h2o", "v1.2.3", "--help", "...",
    ])
    func englishStaysEnglish(_ typed: String) {
        #expect(!convertsToRussian(typed))
    }

    @Test(arguments: ["привет", "я", "и", "Андрюха", "пайтон", "гитхаб", "кубернетес", "ок", "123", "—"])
    func russianStaysRussian(_ typed: String) {
        #expect(!convertsToEnglish(typed))
    }

    @Test func exceptionIsNeverConverted() {
        #expect(convertsToRussian("Ghbdtn,", exceptions: ["ghbdtn"]) == false)
    }

    @Test func unknownLanguageIsIgnored() {
        #expect(!detector.shouldConvert(current: "ghbdtn", language: "de", other: "привет", otherLanguage: "ru"))
    }
}
