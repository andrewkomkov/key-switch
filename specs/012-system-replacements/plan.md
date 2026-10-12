# Implementation Plan: Text replacements of macOS in all apps

**Branch**: `012-system-replacements` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

A pure type in `KeySwitchCore`, `TextReplacements`, holds the list and the match rules. The
app reads the list from the global preferences of macOS. The engine asks for a phrase at the
end of each word, before the layout detector. The change uses the same state as a typo
correction, so the double Shift tap reverts it.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: none new.

**Storage**: `UserDefaults`: one new key, `systemReplacements`. The list itself stays in
macOS. The app holds it in memory.

**Testing**: Swift Testing for the match rules. The end-to-end test gives the engine a list
of its own, so the result does not depend on the list of the user.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| Where is the list? | The key `NSUserDictionaryReplacementItems` of the global preferences | System Settings writes it. No private database, no new permission |
| A list in KeySwitch | No | The user asked for one list. Two lists go out of sync |
| When does the app read the list? | Again if the last read is older than 5 seconds | macOS sends no notification to other apps. The read takes microseconds |
| Apps where macOS applies the list | KeySwitch replaces first | The event tap gets Space before the app. The app then sees the phrase, not the shortcut |
| Order at the end of a word | Replacement first | A shortcut is the decision of the user. The detector guesses |
| Capital first letter | The phrase gets a capital too | `Итд` at the start of a sentence |
| Mark after the shortcut | `.,!?;:` and closing brackets stay after the phrase | macOS replaces at a punctuation mark too |
| How does the user revert? | The state of the typo correction | One gesture for each automatic change |
| Default of the switch | On | The shortcuts are the choice of the user |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The app reads a system list. It writes nothing. Only a reverted shortcut goes to the exceptions. |
| II. Keep the text of the user safe | Pass. A double Shift tap reverts the change, and the shortcut becomes an exception. |
| III. Detection is a pure, tested library | Pass. The match rules are in `KeySwitchCore` with tests. |
| IV. Native, small, free of dependencies | Pass. One dictionary read for each word. |
| V. Spec first | Pass. |

## Project Structure

```text
Sources/KeySwitchCore/
  TextReplacements.swift     list, match rules
Sources/KeySwitch/
  SystemReplacements.swift   read of the macOS list
  Engine.swift               completed word
  Settings.swift             systemReplacements
  SelfTest.swift             scenarios
  Views/SettingsView.swift   switch, count, button
Tests/KeySwitchCoreTests/
  TextReplacementsTests.swift
```
