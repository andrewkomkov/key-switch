# Implementation Plan: Learned words

**Branch**: `006-learned-words` | **Date**: 2026-10-09 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

A learner in `KeySwitchCore` counts unknown words in memory. After 3 counts, or after one
manual conversion, the word goes to a list in the settings. The detector gives each learned
word the rank of a frequent dictionary word.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: none new.

**Storage**: `UserDefaults`: `learnWords` and `learnedWords`. An entry is the language code
and the word, for example `ru:гит`.

**Testing**: Swift Testing for the learner and for the detector with learned words. The
end-to-end test for the two ways to learn.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| When does a word become learned? | 3 counts in one session, or 1 manual conversion | One entry can be a mistake. A conversion is a clear signal |
| Which words are counted? | 3 to 24 letters of the language, absent from the dictionary, possible for the letter model | Random letters from the incorrect layout must stay out |
| Rank of a learned word | 4000 | Below the limit for short words (5000) and below the limit of the typo correction (15,000) |
| Where are the counts? | In memory | Only a word that passed the limit goes to the disk |
| Default | Off | The feature writes typed words to the disk |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Needs an amendment. Version 1.1.0 lets the app store learned words when the user sets learning to on. |
| II. Keep the text of the user safe | Pass. The user can see and remove each learned word. |
| III. Detection is a pure, tested library | Pass. The learner and the rank logic are in `KeySwitchCore` with tests. |
| IV. Native, small, free of dependencies | Pass. |
| V. Spec first | Pass. |

## Project Structure

```text
.specify/memory/constitution.md       amendment of principle I
Sources/KeySwitchCore/
  WordLearner.swift   counts and limit
  Detector.swift      learned words, isLearnable
Sources/KeySwitch/
  Engine.swift        count at the end of a word, learn on a manual conversion
  Settings.swift      learnWords, learnedWords
  Views/SettingsView.swift  switch and list
  SelfTest.swift      scenarios
Tests/KeySwitchCoreTests/WordLearnerTests.swift
```
