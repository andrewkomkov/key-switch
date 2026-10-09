import Foundation

/// Recognizes lone taps of one modifier key from modifier events: a single tap, a double
/// tap, and each further tap of the same series.
public struct TapRecognizer: Sendable {
    public enum Action: Sendable {
        case none
        case single
        case double
        /// The third and each later tap of a series.
        case repeated
    }

    /// A press longer than this is a hold, not a tap.
    public var tapTimeout: TimeInterval = 0.35
    /// Maximum time between the releases of two taps of a series.
    public var doubleTapInterval: TimeInterval = 0.45

    private var isDown = false
    private var armed = false
    private var downTime: TimeInterval = 0
    private var lastTap: TimeInterval?
    private var inSeries = false

    public init() {}

    public mutating func flagsChanged(isDown down: Bool, otherModifiers: Bool, time: TimeInterval) -> Action {
        defer { isDown = down }
        if otherModifiers {
            interrupt()
            return .none
        }
        if down, !isDown {
            armed = true
            downTime = time
            return .none
        }
        guard !down, isDown, armed else { return .none }
        armed = false
        guard time - downTime <= tapTimeout else {
            interrupt()
            return .none
        }
        defer { lastTap = time }
        if let previous = lastTap, time - previous <= doubleTapInterval {
            if inSeries { return .repeated }
            inSeries = true
            return .double
        }
        inSeries = false
        return .single
    }

    /// A key or a mouse button went down: the modifier is a modifier now, not a tap.
    public mutating func interrupt() {
        armed = false
        lastTap = nil
        inSeries = false
    }
}
