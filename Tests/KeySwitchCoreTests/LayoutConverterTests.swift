import Testing
import KeySwitchCore

@Suite struct LayoutConverterTests {
    let converter = LayoutConverter(pairs:
        Array(zip(Keyboard.latin, Keyboard.cyrillic))
        + zip(Keyboard.latin, Keyboard.cyrillic).map {
            (Character($0.uppercased()), Character($1.uppercased()))
        })

    @Test func findsTheDirectionFromTheLetters() {
        #expect(converter.direction(for: "ghbdtn vbh") == .forward)
        #expect(converter.direction(for: "руддщ цщкдв") == .backward)
        #expect(converter.direction(for: "hello мир and more") == .forward)
        #expect(converter.direction(for: "123 ,.;") == nil)
        #expect(converter.direction(for: "") == nil)
    }

    @Test func convertsEachKeyAndKeepsTheRest() {
        #expect(converter.convert("Ghbdtn, vbh!\n123", .forward) == "Привет, мир!\n123".replacingOccurrences(of: ",", with: "б"))
        #expect(converter.convert("Руддщ цщкдв", .backward) == "Hello world")
        #expect(converter.convert("хорошо", .backward) == "[jhjij")
    }

    @Test func aRoundTripGivesTheSameText() {
        let text = "Ghbdtn vbh; 'nj ntcn."
        #expect(converter.convert(converter.convert(text, .forward), .backward) == text)
    }
}
