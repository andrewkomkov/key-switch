import Foundation

/// Recognizes a lone Shift tap and a double tap from modifier events.
public struct ShiftTapRecognizer: Sendable {
    public enum Action: Sendable {
        case none
        case switchLayout
        case convert
    }

    /// A press longer than this is a hold, not a tap.
    public var tapTimeout: TimeInterval = 0.35
    /// Maximum time between the releases of two taps.
    public var doubleTapInterval: TimeInterval = 0.45

    private var isDown = false
    private var armed = false
    private var downTime: TimeInterval = 0
    private var lastTap: TimeInterval?

    public init() {}

    public mutating func flagsChanged(shiftDown: Bool, otherModifiers: Bool, time: TimeInterval) -> Action {
        defer { isDown = shiftDown }
        if otherModifiers {
            interrupt()
            return .none
        }
        if shiftDown, !isDown {
            armed = true
            downTime = time
            return .none
        }
        guard !shiftDown, isDown, armed else { return .none }
        armed = false
        guard time - downTime <= tapTimeout else {
            lastTap = nil
            return .none
        }
        if let previous = lastTap, time - previous <= doubleTapInterval {
            lastTap = nil
            return .convert
        }
        lastTap = time
        return .switchLayout
    }

    /// A key or a mouse button went down: Shift is a modifier now, not a tap.
    public mutating func interrupt() {
        armed = false
        lastTap = nil
    }
}
