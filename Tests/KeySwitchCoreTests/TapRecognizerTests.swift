import Testing
import KeySwitchCore

@Suite struct TapRecognizerTests {
    var recognizer = TapRecognizer()

    mutating func tap(at time: Double, held: Double = 0.05) -> TapRecognizer.Action {
        _ = recognizer.flagsChanged(isDown: true, otherModifiers: false, time: time)
        return recognizer.flagsChanged(isDown: false, otherModifiers: false, time: time + held)
    }

    @Test mutating func singleTap() {
        #expect(tap(at: 0) == .single)
    }

    @Test mutating func aSeriesOfTaps() {
        #expect(tap(at: 0) == .single)
        #expect(tap(at: 0.2) == .double)
        #expect(tap(at: 0.4) == .repeated)
        #expect(tap(at: 0.6) == .repeated)
        #expect(tap(at: 2) == .single)
        #expect(tap(at: 2.2) == .double)
    }

    @Test mutating func slowSecondTapStartsANewSeries() {
        #expect(tap(at: 0) == .single)
        #expect(tap(at: 1) == .single)
    }

    @Test mutating func holdIsNotATap() {
        #expect(tap(at: 0, held: 1) == .none)
    }

    @Test mutating func modifierWithAKeyIsNotATap() {
        _ = recognizer.flagsChanged(isDown: true, otherModifiers: false, time: 0)
        recognizer.interrupt()
        #expect(recognizer.flagsChanged(isDown: false, otherModifiers: false, time: 0.05) == .none)
    }

    @Test mutating func keyBetweenTapsEndsTheSeries() {
        #expect(tap(at: 0) == .single)
        #expect(tap(at: 0.2) == .double)
        recognizer.interrupt()
        #expect(tap(at: 0.4) == .single)
    }

    @Test mutating func withAnotherModifierIsNotATap() {
        _ = recognizer.flagsChanged(isDown: true, otherModifiers: false, time: 0)
        _ = recognizer.flagsChanged(isDown: true, otherModifiers: true, time: 0.01)
        #expect(recognizer.flagsChanged(isDown: false, otherModifiers: true, time: 0.05) == .none)
        #expect(recognizer.flagsChanged(isDown: false, otherModifiers: false, time: 0.06) == .none)
    }
}
