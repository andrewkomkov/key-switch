import Testing
import KeySwitchCore

@Suite struct EmojiCodesTests {
    static let codes = EmojiCodes(list: Fixtures.text("Resources/emoji.txt"))

    @Test func theListHasTheCodesOfGitHub() {
        #expect(Self.codes.count == 1913)
    }

    @Test(arguments: [
        (":fire:", "\u{1F525}"),
        (":+1:", "\u{1F44D}"),
        (":thumbsup:", "\u{1F44D}"),
        (":heart:", "\u{2764}\u{FE0F}"),
        (":ru:", "\u{1F1F7}\u{1F1FA}"),
        (":100:", "\u{1F4AF}"),
    ])
    func aCodeGivesItsEmoji(typed: String, expected: String) {
        #expect(Self.codes.emoji(for: typed) == expected)
    }

    @Test(arguments: [
        "fire", ":fire", "fire:", "::", ":", "", ":Fire:", ":nosuchcode:", "a:fire:", ":fire:!", "10:30:", ":fire::",
    ])
    func otherTextStays(typed: String) {
        #expect(Self.codes.emoji(for: typed) == nil)
    }

    @Test func aBrokenLineIsIgnored() {
        let codes = EmojiCodes(list: "ok\t\u{1F44C}\nbroken\n\nthree\tparts\there\n")
        #expect(codes.count == 1)
        #expect(codes.emoji(for: ":ok:") == "\u{1F44C}")
    }
}
