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

/// The word before the caret and the spaces after it, as keystrokes.
public struct WordBuffer: Sendable {
    public static let capacity = 64

    public private(set) var word: [Keystroke] = []
    public private(set) var trailingSpaces: [Keystroke] = []
    /// The word was converted by the detector and the user has not touched it since.
    public var autoConverted = false
    /// The user converted the word by hand. The detector must leave it alone.
    public var manuallyConverted = false
    /// The spelling of the word was corrected. The screen no longer shows these keys,
    /// so the only safe operations are more spaces and a revert.
    public var typoCorrected = false
    private var overflowed = false

    public init() {}

    public var isEmpty: Bool { word.isEmpty }
    public var all: [Keystroke] { word + trailingSpaces }

    public mutating func append(_ key: Keystroke, isSpace: Bool) {
        if isSpace {
            overflowed = false
            if !word.isEmpty { trailingSpaces.append(key) }
            return
        }
        if !trailingSpaces.isEmpty { reset() }
        if overflowed { return }
        if word.count == Self.capacity {
            reset()
            overflowed = true
            return
        }
        word.append(key)
        autoConverted = false
        manuallyConverted = false
    }

    public mutating func deleteLast() {
        if typoCorrected { return reset() }
        if !trailingSpaces.isEmpty {
            trailingSpaces.removeLast()
        } else if !word.isEmpty {
            word.removeLast()
            if word.isEmpty { reset() }
        }
        autoConverted = false
    }

    public mutating func reset() {
        self = WordBuffer()
    }
}
