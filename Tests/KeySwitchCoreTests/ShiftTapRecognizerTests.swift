import Testing
import KeySwitchCore

@Suite struct ShiftTapRecognizerTests {
    var recognizer = ShiftTapRecognizer()

    mutating func tap(at time: Double, held: Double = 0.05) -> ShiftTapRecognizer.Action {
        _ = recognizer.flagsChanged(shiftDown: true, otherModifiers: false, time: time)
        return recognizer.flagsChanged(shiftDown: false, otherModifiers: false, time: time + held)
    }

    @Test mutating func singleTapSwitches() {
        #expect(tap(at: 0) == .switchLayout)
    }

    @Test mutating func doubleTapConverts() {
        #expect(tap(at: 0) == .switchLayout)
        #expect(tap(at: 0.2) == .convert)
        #expect(tap(at: 0.4) == .switchLayout)
    }

    @Test mutating func slowSecondTapSwitchesAgain() {
        #expect(tap(at: 0) == .switchLayout)
        #expect(tap(at: 1) == .switchLayout)
    }

    @Test mutating func holdIsNotATap() {
        #expect(tap(at: 0, held: 1) == .none)
    }

    @Test mutating func shiftWithAKeyIsNotATap() {
        _ = recognizer.flagsChanged(shiftDown: true, otherModifiers: false, time: 0)
        recognizer.interrupt()
        #expect(recognizer.flagsChanged(shiftDown: false, otherModifiers: false, time: 0.05) == .none)
    }

    @Test mutating func keyBetweenTapsCancelsTheDoubleTap() {
        #expect(tap(at: 0) == .switchLayout)
        recognizer.interrupt()
        #expect(tap(at: 0.2) == .switchLayout)
    }

    @Test mutating func shiftWithAnotherModifierIsNotATap() {
        _ = recognizer.flagsChanged(shiftDown: true, otherModifiers: false, time: 0)
        _ = recognizer.flagsChanged(shiftDown: true, otherModifiers: true, time: 0.01)
        #expect(recognizer.flagsChanged(shiftDown: false, otherModifiers: true, time: 0.05) == .none)
        #expect(recognizer.flagsChanged(shiftDown: false, otherModifiers: false, time: 0.06) == .none)
    }
}
