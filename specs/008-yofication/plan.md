# Implementation Plan: The letter ё

**Branch**: `008-yofication` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

A new type in `KeySwitchCore`, `Yoficator`, reads a dictionary of words that always have
`ё`. The engine asks it for each completed word and for each converted word. The change uses
the same state as a typo correction, so the double Shift tap reverts it.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: none new. One new data file, `Resources/ru-yo.txt`.

**Storage**: `UserDefaults`: one new key, `yofication`.

**Testing**: Swift Testing for the dictionary format, the case rules and the full list. The
end-to-end test for the typed word, the revert and the conversions.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| Source of the words | The "safe" dictionary of eyo-kernel, MIT license, 106,654 word forms | It has no word such as `все`, where the two spellings are correct |
| Format of the file | The source format: a stem and its endings in one line | The file is 0.9 MB. The full list of forms is 3 times larger |
| How does the user revert? | The state of the typo correction | One gesture for each automatic change, and an exception after it |
| Default of the switch | Off | The option changes text that has no error |
| Selected text | No change | A selection conversion must give the same text back on the second gesture |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The word stays in memory. Only a reverted word goes to the exceptions. |
| II. Keep the text of the user safe | Pass. A double Shift tap reverts the change. The list has no ambiguous word. |
| III. Detection is a pure, tested library | Pass. `Yoficator` is in `KeySwitchCore` with tests. |
| IV. Native, small, free of dependencies | Pass. The lookup is one dictionary read. |
| V. Spec first | Pass. |

## Project Structure

```text
Sources/KeySwitchCore/
  Yoficator.swift          dictionary and case rules
Sources/KeySwitch/
  Engine.swift             completed word, converted word
  Settings.swift           yofication
  SelfTest.swift           scenarios
  Views/SettingsView.swift switch
Resources/
  ru-yo.txt  ru-yo.LICENSE.txt  NOTICE.md
Tests/KeySwitchCoreTests/
  YoficatorTests.swift
```
