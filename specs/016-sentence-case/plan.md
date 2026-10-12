# Implementation Plan: Capital letter at the start of a sentence

**Branch**: `016-sentence-case` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

A new pure type in `KeySwitchCore`, `SentenceCase`, gets a completed word and the word before
it. If a sentence starts there, the type gives the word with a capital. `WordBuffer` gives the
keys of the previous word. The engine applies the rule to each completed word, also after a
layout conversion, a typo correction and the `ё` change.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: none new.

**Storage**: `UserDefaults`: one new key, `capitalizeSentences`.

**Testing**: Swift Testing for the rules and for the previous word of the buffer. The
end-to-end test for the typed word, the revert and the converted word.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| When does the app change the word? | At the end of the word | The same moment and the same revert as each other automatic change |
| How does the app know the start of a sentence? | The previous word of the typed phrase ends with `.`, `!` or `?` | The app does not read the text of other apps. The phrase buffer is all that it has |
| After Return | No change | A new line in a terminal or in code is not a sentence |
| Abbreviations | A short list, a word with a full stop in it, a word of one letter | `т.е.`, `etc.`, initials |
| Which word changes? | Small letters only, with possible punctuation at the two ends | `iPhone`, a path and a code stay |
| Default of the switch | Off | The option changes correct words in each app |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The phrase stays in memory. Only a reverted word goes to the exceptions. |
| II. Keep the text of the user safe | Pass. A double Shift tap reverts the change, and the word becomes an exception. |
| III. Detection is a pure, tested library | Pass. `SentenceCase` is in `KeySwitchCore` with tests. |
| IV. Native, small, free of dependencies | Pass. |
| V. Spec first | Pass. |

## Project Structure

```text
Sources/KeySwitchCore/
  SentenceCase.swift         rules
  WordBuffer.swift           previous word
Sources/KeySwitch/
  Engine.swift, Settings.swift, SelfTest.swift, Views/SettingsView.swift
Tests/KeySwitchCoreTests/
  SentenceCaseTests.swift, WordBufferTests.swift
```
