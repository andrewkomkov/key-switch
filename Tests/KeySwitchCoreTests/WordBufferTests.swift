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
}
