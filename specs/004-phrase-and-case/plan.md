# Implementation Plan: Phrase conversion and case change

**Branch**: `004-phrase-and-case` | **Date**: 2026-10-09 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

The word buffer keeps the full phrase and a span: the words that a conversion changes. One
tap recognizer serves Shift and Option and reports a single tap, a double tap and each later
tap of a series. A later Shift tap makes the span one word longer. A double Option tap sends
the last word through a case cycle.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: none new.

**Storage**: `UserDefaults`: one new key, `caseGesture`.

**Testing**: Swift Testing for the buffer, the recognizer and the case cycle. The end-to-end
test for the gestures.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| How does the user add a word? | One more tap in the same series | A later double tap keeps its function: convert back |
| Where is the phrase? | In `WordBuffer`, 256 keys | The buffer already knows the keys and the spaces |
| Gesture for the case | Double Option tap | It follows the Shift gesture, and macOS does not use it |
| Buffer after a case change | New keys with a different Shift state | The buffer stays true, and a layout conversion still works |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The phrase stays in memory. A caret movement clears it. |
| II. Keep the text of the user safe | Pass. A double Shift tap converts the same words back. |
| III. Detection is a pure, tested library | Pass. The new logic is in `KeySwitchCore` with tests. |
| IV. Native, small, free of dependencies | Pass. |
| V. Spec first | Pass. |

## Project Structure

```text
Sources/KeySwitchCore/
  TapRecognizer.swift   replaces ShiftTapRecognizer, adds the repeated tap
  WordBuffer.swift      phrase, span, extend, replaceWord
  CaseCycler.swift      case cycle
Sources/KeySwitch/
  Engine.swift          two recognizers, phrase extension, case change
  Settings.swift        caseGesture
  SelfTest.swift        scenarios
Tests/KeySwitchCoreTests/
  TapRecognizerTests.swift  WordBufferTests.swift  CaseCyclerTests.swift
```
