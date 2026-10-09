import Foundation

/// Decides whether a finished word was typed in the wrong layout.
public struct Detector: Sendable {
    public struct Thresholds: Sendable {
        /// Short words convert only when the other reading is this frequent.
        public var shortWordMaxRank = 5000
        /// Minimum length for a conversion that rests on the trigram model alone.
        public var minModelLength = 4
        /// Minimum trigram score of the other reading.
        public var minScore: Float = -3.4
        /// The other reading must beat the current one by this much.
        public var margin: Float = 1.2
        /// A letter run of the current reading that is a word this frequent blocks the conversion.
        public var knownRunMaxRank = 20_000
        /// If the two readings are words, the current one must be this many times rarer.
        public var rankRatio = 10.0
        public var rareWordMinRank = 8000

        public init() {}
    }

    private let models: [String: LanguageModel]
    public var thresholds = Thresholds()

    public init(models: [LanguageModel]) {
        self.models = Dictionary(uniqueKeysWithValues: models.map { ($0.language, $0) })
    }

    public func supports(_ language: String) -> Bool {
        models[language] != nil
    }

    /// - Parameters:
    ///   - current: the keys read in the active layout, as they appear on screen.
    ///   - other: the same keys read in the candidate layout.
    public func shouldConvert(
        current: String, language: String,
        other: String, otherLanguage: String,
        exceptions: Set<String> = []
    ) -> Bool {
        guard let currentModel = models[language], let otherModel = models[otherLanguage] else {
            return false
        }
        if current.contains(where: \.isNumber) { return false }

        let currentCore = Self.core(of: current)
        guard currentCore.count > 1, !exceptions.contains(currentCore) else { return false }
        let otherCore = Self.core(of: other)
        guard otherCore.count > 1 else { return false }

        let otherRank = Self.worstRank(of: otherCore, in: otherModel)
        if let currentRank = Self.worstRank(of: currentCore, in: currentModel) {
            // Both readings are words, for example `vs` and `мы`. Convert only if the
            // current one is rare and the other one is far more frequent.
            guard let otherRank else { return false }
            return currentRank >= thresholds.rareWordMinRank && Double(currentRank) > Double(otherRank) * thresholds.rankRatio
        }
        if let otherRank {
            return otherCore.count > 3 || otherRank < thresholds.shortWordMaxRank
        }

        // Neither reading is a known word: compare how plausible they look.
        guard otherCore.count >= thresholds.minModelLength,
              let otherScore = otherModel.score(otherCore),
              otherScore >= thresholds.minScore
        else { return false }

        var currentScore = -Float.infinity
        for run in currentCore.split(whereSeparator: { !currentModel.isLetter($0) }) where run.count > 2 {
            let run = String(run)
            if let rank = currentModel.rank(of: run), rank < thresholds.knownRunMaxRank { return false }
            currentScore = max(currentScore, currentModel.score(run) ?? -.infinity)
        }
        return otherScore - currentScore >= thresholds.margin
    }

    /// The exception key for a word: lowercased, without the punctuation around it.
    public static func core(of word: String) -> String {
        let lowered = LanguageModel.normalize(word)
        guard let first = lowered.firstIndex(where: \.isLetter),
              let last = lowered.lastIndex(where: \.isLetter)
        else { return "" }
        return String(lowered[first...last])
    }

    /// Rank of the least frequent part of a word such as `don't` or `кто-то`.
    /// `nil` if a part is not in the dictionary.
    private static func worstRank(of core: String, in model: LanguageModel) -> Int? {
        var worst = 0
        for part in core.split(separator: "-", omittingEmptySubsequences: false) {
            var stem = part
            if let apostrophe = part.firstIndex(where: { $0 == "'" || $0 == "’" }) {
                guard contractions.contains(String(part[part.index(after: apostrophe)...])) else { return nil }
                stem = part[..<apostrophe]
            }
            guard let rank = model.rank(of: String(stem)) else { return nil }
            worst = max(worst, rank)
        }
        return worst
    }

    private static let contractions: Set<String> = ["s", "t", "d", "m", "ll", "re", "ve"]
}
