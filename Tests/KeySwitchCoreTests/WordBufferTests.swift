import Testing
import KeySwitchCore

@Suite struct WordBufferTests {
    let a = Keystroke(keyCode: 0)
    let space = Keystroke(keyCode: 49)

    @Test func keepsTheLastWordAndItsSpaces() {
        var buffer = WordBuffer()
        buffer.append(a, isSpace: false)
        buffer.append(space, isSpace: true)
        buffer.append(Keystroke(keyCode: 1), isSpace: false)
        buffer.append(Keystroke(keyCode: 2), isSpace: false)
        buffer.append(space, isSpace: true)
        #expect(buffer.word.map(\.keyCode) == [1, 2])
        #expect(buffer.all.count == 3)
    }

    @Test func leadingSpacesAreIgnored() {
        var buffer = WordBuffer()
        buffer.append(space, isSpace: true)
        #expect(buffer.all.isEmpty)
    }

    @Test func deleteRemovesSpacesFirst() {
        var buffer = WordBuffer()
        buffer.append(a, isSpace: false)
        buffer.append(space, isSpace: true)
        buffer.deleteLast()
        #expect(buffer.all == [a])
        buffer.deleteLast()
        #expect(buffer.isEmpty)
        buffer.deleteLast()
        #expect(buffer.isEmpty)
    }

    @Test func typingClearsTheConversionMarks() {
        var buffer = WordBuffer()
        buffer.append(a, isSpace: false)
        buffer.autoConverted = true
        buffer.manuallyConverted = true
        buffer.append(a, isSpace: false)
        #expect(!buffer.autoConverted)
        #expect(!buffer.manuallyConverted)
    }

    @Test func tooLongWordIsDroppedUntilTheNextSpace() {
        var buffer = WordBuffer()
        for _ in 0...WordBuffer.capacity + 5 { buffer.append(a, isSpace: false) }
        #expect(buffer.isEmpty)
        buffer.append(space, isSpace: true)
        buffer.append(a, isSpace: false)
        #expect(buffer.word == [a])
    }

    @Test func deleteAfterATypoCorrectionForgetsTheWord() {
        var buffer = WordBuffer()
        buffer.append(a, isSpace: false)
        buffer.typoCorrected = true
        buffer.append(space, isSpace: true)
        #expect(buffer.typoCorrected)
        buffer.deleteLast()
        #expect(buffer.isEmpty)
        #expect(!buffer.typoCorrected)
    }

    @Test func aNewWordClearsTheTypoMark() {
        var buffer = WordBuffer()
        buffer.append(a, isSpace: false)
        buffer.typoCorrected = true
        buffer.append(space, isSpace: true)
        buffer.append(a, isSpace: false)
        #expect(!buffer.typoCorrected)
    }

    func phrase(_ words: [[UInt16]], trailingSpace: Bool = true) -> WordBuffer {
        var buffer = WordBuffer()
        for (index, word) in words.enumerated() {
            for code in word { buffer.append(Keystroke(keyCode: code), isSpace: false) }
            if index < words.count - 1 || trailingSpace { buffer.append(space, isSpace: true) }
        }
        return buffer
    }

    @Test func extendAddsOneWordAtATime() {
        var buffer = phrase([[1], [2, 3], [4]])
        #expect(buffer.all.map(\.keyCode) == [4, 49])
        do { let extended = buffer.extend(); #expect(extended) }
        #expect(buffer.all.map(\.keyCode) == [2, 3, 49, 4, 49])
        do { let extended = buffer.extend(); #expect(extended) }
        #expect(buffer.all.map(\.keyCode) == [1, 49, 2, 3, 49, 4, 49])
        do { let extended = buffer.extend(); #expect(!extended) }
        #expect(buffer.word.map(\.keyCode) == [4])
    }

    @Test func aNewWordShrinksTheSpan() {
        var buffer = phrase([[1], [2]])
        do { let extended = buffer.extend(); #expect(extended) }
        buffer.append(Keystroke(keyCode: 3), isSpace: false)
        #expect(buffer.all.map(\.keyCode) == [3])
    }

    @Test func deleteGoesBackIntoTheEarlierWord() {
        var buffer = phrase([[1, 2], [3]], trailingSpace: false)
        buffer.manuallyConverted = true
        buffer.deleteLast()
        #expect(buffer.word.map(\.keyCode) == [1, 2])
        #expect(!buffer.manuallyConverted)
        buffer.deleteLast()
        buffer.deleteLast()
        #expect(buffer.word.map(\.keyCode) == [1])
    }

    @Test func replaceWordKeepsTheRestOfThePhrase() {
        var buffer = phrase([[1], [2, 3]])
        buffer.replaceWord([Keystroke(keyCode: 2, shift: true), Keystroke(keyCode: 3)])
        #expect(buffer.word.map(\.shift) == [true, false])
        do { let extended = buffer.extend(); #expect(extended) }
        #expect(buffer.all.count == 5)
        buffer.replaceWord([Keystroke(keyCode: 9)])
        #expect(buffer.word.map(\.keyCode) == [2, 3])
    }

    @Test func aLongPhraseDropsItsOldestWords() {
        var buffer = WordBuffer()
        for _ in 0..<200 {
            buffer.append(a, isSpace: false)
            buffer.append(a, isSpace: false)
            buffer.append(space, isSpace: true)
        }
        buffer.append(Keystroke(keyCode: 7), isSpace: false)
        #expect(buffer.word.map(\.keyCode) == [7])
        do { let extended = buffer.extend(); #expect(extended) }
    }

    @Test func aTypoCorrectionStopsThePhrase() {
        var buffer = phrase([[1], [2]])
        buffer.typoCorrected = true
        do { let extended = buffer.extend(); #expect(!extended) }
    }
}
