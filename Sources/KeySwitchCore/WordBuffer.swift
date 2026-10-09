/// A key press that does not depend on the layout.
public struct Keystroke: Hashable, Sendable {
    public var keyCode: UInt16
    public var shift: Bool
    public var capsLock: Bool

    public init(keyCode: UInt16, shift: Bool = false, capsLock: Bool = false) {
        self.keyCode = keyCode
        self.shift = shift
        self.capsLock = capsLock
    }
}

/// The phrase before the caret, as keystrokes. A conversion works on the span: the last
/// word, the spaces after it, and the earlier words that the user added to it.
public struct WordBuffer: Sendable {
    public static let capacity = 256

    private var keys: [Keystroke] = []
    private var isSpace: [Bool] = []
    /// Earlier words that are part of the span.
    private var extraWords = 0
    /// The word was converted by the detector and the user has not touched it since.
    public var autoConverted = false
    /// The user converted the word by hand. The detector must leave it alone.
    public var manuallyConverted = false
    /// The spelling of the word was corrected. The screen no longer shows these keys,
    /// so the only safe operations are more spaces and a revert.
    public var typoCorrected = false
    private var overflowed = false

    public init() {}

    public var isEmpty: Bool { keys.isEmpty }
    public var word: [Keystroke] { Array(keys[wordStart..<wordEnd]) }
    public var trailingSpaces: [Keystroke] { Array(keys[wordEnd...]) }
    /// The span: what a conversion replaces.
    public var all: [Keystroke] { Array(keys[spanStart(words: extraWords + 1)...]) }

    public mutating func append(_ key: Keystroke, isSpace space: Bool) {
        if space {
            overflowed = false
            if !keys.isEmpty { push(key, isSpace: true) }
            return
        }
        if isSpace.last == true {
            if typoCorrected { reset() }
            clearMarks()
        }
        if overflowed { return }
        if keys.count == Self.capacity, !dropOldestWord() {
            reset()
            overflowed = true
            return
        }
        push(key, isSpace: false)
        autoConverted = false
        manuallyConverted = false
    }

    public mutating func deleteLast() {
        if typoCorrected { return reset() }
        guard !keys.isEmpty else { return }
        let start = wordStart
        keys.removeLast()
        isSpace.removeLast()
        extraWords = 0
        autoConverted = false
        // The caret is now in an earlier word: the marks were about the deleted one.
        if keys.isEmpty || wordStart != start { clearMarks() }
    }

    /// Adds one earlier word to the span. Returns `false` if there is none.
    public mutating func extend() -> Bool {
        guard !typoCorrected,
              spanStart(words: extraWords + 2) < spanStart(words: extraWords + 1)
        else { return false }
        extraWords += 1
        return true
    }

    /// Puts other keys in place of the last word, for example the same keys with Shift.
    public mutating func replaceWord(_ replacement: [Keystroke]) {
        guard replacement.count == wordEnd - wordStart else { return }
        keys.replaceSubrange(wordStart..<wordEnd, with: replacement)
    }

    public mutating func reset() {
        self = WordBuffer()
    }

    private mutating func push(_ key: Keystroke, isSpace space: Bool) {
        keys.append(key)
        isSpace.append(space)
    }

    /// Makes room at the front. Returns `false` if the phrase is one long word.
    private mutating func dropOldestWord() -> Bool {
        guard var cut = isSpace.firstIndex(of: true) else { return false }
        while cut < keys.count, isSpace[cut] { cut += 1 }
        keys.removeFirst(cut)
        isSpace.removeFirst(cut)
        return true
    }

    private mutating func clearMarks() {
        autoConverted = false
        manuallyConverted = false
        typoCorrected = false
        extraWords = 0
    }

    private var wordEnd: Int {
        var index = keys.count
        while index > 0, isSpace[index - 1] { index -= 1 }
        return index
    }

    private var wordStart: Int { spanStart(words: 1) }

    /// Start of the span that has up to `count` words.
    private func spanStart(words count: Int) -> Int {
        var index = wordEnd
        for word in 0..<count {
            if word > 0 {
                var previous = index
                while previous > 0, isSpace[previous - 1] { previous -= 1 }
                if previous == 0 { break }
                index = previous
            }
            while index > 0, !isSpace[index - 1] { index -= 1 }
        }
        return index
    }
}
