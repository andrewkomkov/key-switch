import Foundation
import KeySwitchCore

/// The letter keys of the US and the Russian layout, in the same key order.
enum Keyboard {
    static let latin = Array("`qwertyuiop[]asdfghjkl;'zxcvbnm,.")
    static let cyrillic = Array("ёйцукенгшщзхъфывапролджэячсмитьбю")

    static let toCyrillic = Dictionary(uniqueKeysWithValues: zip(latin, cyrillic))
    static let toLatin = Dictionary(uniqueKeysWithValues: zip(cyrillic, latin))

    static func asCyrillic(_ text: String) -> String {
        convert(text, with: toCyrillic)
    }

    static func asLatin(_ text: String) -> String {
        convert(text, with: toLatin)
    }

    private static func convert(_ text: String, with map: [Character: Character]) -> String {
        String(text.map { character in
            if let mapped = map[character] { return mapped }
            if let mapped = map[Character(character.lowercased())] { return Character(mapped.uppercased()) }
            return character
        })
    }
}

enum Fixtures {
    static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    static func text(_ path: String) -> String {
        try! String(contentsOf: root.appendingPathComponent(path), encoding: .utf8)
    }

    static func words(_ path: String, limit: Int = .max) -> [String] {
        text(path).split(separator: "\n").prefix(limit).map { String($0.split(separator: " ")[0]) }
    }

    static let detector = Detector(models: [
        .russian(wordList: text("Resources/ru.txt")),
        .english(wordList: text("Resources/en.txt") + text("Resources/en-tech.txt")),
    ])
}
