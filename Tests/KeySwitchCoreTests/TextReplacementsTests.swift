import Testing
import KeySwitchCore

@Suite struct TextReplacementsTests {
    static let list = TextReplacements([
        ("omw", "On my way!"),
        ("итд", "и так далее"),
        ("^pd", "xc5-for-automotive-pd"),
        ("brb.", "be right back"),
        ("Еее", "Еее"),
        ("в пути", "Я в пути!"),
        ("sig", "Regards,\nAndrew"),
        ("", "empty"),
        ("gone", ""),
    ])

    @Test func entriesThatCannotWorkAreIgnored() {
        #expect(Self.list.count == 4)
        for word in ["Еее", "в", "пути", "sig", "gone", ""] {
            #expect(Self.list.expansion(for: word) == nil)
        }
    }

    @Test(arguments: [
        ("omw", "On my way!"),
        ("итд", "и так далее"),
        ("Итд", "И так далее"),
        ("^pd", "xc5-for-automotive-pd"),
        ("итд,", "и так далее,"),
        ("omw).", "On my way!)."),
        ("brb.", "be right back"),
        ("Brb.", "Be right back"),
    ])
    func aShortcutGivesItsPhrase(typed: String, expected: String) {
        #expect(Self.list.expansion(for: typed) == expected)
    }

    @Test(arguments: ["om", "omww", "OMW", "oMw", "(omw", "итд-", "...", "brb"])
    func otherWordsStay(typed: String) {
        #expect(Self.list.expansion(for: typed) == nil)
    }
}
