/// Converts text between two layouts: each character becomes the character that the same
/// key gives in the other layout.
public struct LayoutConverter: Sendable {
    public enum Direction: Sendable {
        case forward
        case backward
    }

    private let forward: [Character: Character]
    private let backward: [Character: Character]

    /// - Parameter pairs: what one key with the same modifiers gives in the first and in the
    ///   second layout. If a character comes up twice, the first pair wins.
    public init(pairs: [(Character, Character)]) {
        var forward: [Character: Character] = [:], backward: [Character: Character] = [:]
        for (first, second) in pairs {
            if forward[first] == nil { forward[first] = second }
            if backward[second] == nil { backward[second] = first }
        }
        self.forward = forward
        self.backward = backward
    }

    /// The layout that owns more letters of the text is the source. `nil` if no letter
    /// belongs to only one of the layouts.
    public func direction(for text: String) -> Direction? {
        var first = 0, second = 0
        for character in text where character.isLetter {
            let inFirst = forward[character] != nil, inSecond = backward[character] != nil
            if inFirst, !inSecond { first += 1 }
            if inSecond, !inFirst { second += 1 }
        }
        if first == 0, second == 0 { return nil }
        return first >= second ? .forward : .backward
    }

    public func convert(_ text: String, _ direction: Direction) -> String {
        let map = direction == .forward ? forward : backward
        return String(text.map { map[$0] ?? $0 })
    }
}
