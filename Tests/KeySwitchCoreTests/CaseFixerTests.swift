import Testing
import KeySwitchCore

@Suite struct CaseFixerTests {
    static let known: Set<String> = ["привет", "hello", "что", "tvs", "ids", "ios", "да"]

    private func fixed(_ text: String) -> String? {
        CaseFixer.fixed(text) { Self.known.contains($0) }
    }

    @Test(arguments: [
        ("ПРивет", "Привет"),
        ("HEllo", "Hello"),
        ("ЧТо", "Что"),
        ("пРИВЕТ", "Привет"),
        ("hELLO", "Hello"),
        ("«ПРивет,", "«Привет,"),
        ("(hELLO)!", "(Hello)!"),
    ])
    func accidentalCapitalsGoAway(typed: String, expected: String) {
        #expect(fixed(typed) == expected)
    }

    @Test(arguments: [
        "Привет", "привет", "ПРИВЕТ", "ПРИвет", "ПривеТ", "прИВЕТ",
        "TVs", "IDs", "iOS", "ДА", "Да", "дА",
        "HEllo-hello", "", "123", "...",
    ])
    func otherWordsStay(typed: String) {
        #expect(fixed(typed) == nil)
    }

    @Test func anUnknownWordStays() {
        #expect(fixed("OSes") == nil)
        #expect(fixed("МВтч") == nil)
        #expect(fixed("gBPS") == nil)
    }
}
