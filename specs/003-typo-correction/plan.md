# Implementation Plan: Typo correction

**Branch**: `003-typo-correction` | **Date**: 2026-10-09 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

When the user completes a word, the layout detector examines it first. If the word stays as
typed and the typo option is on, the app asks the macOS spelling checker for a sure
correction. Pure rules in `KeySwitchCore` select the words to examine and the corrections to
accept. A correction must be a word of the frequency list. A double Shift tap reverts the correction.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: AppKit `NSSpellChecker`. No third-party packages.

**Storage**: `UserDefaults`: one new key, `fixTypos`.

**Testing**: Swift Testing for the rules. The end-to-end test for the full path.

**Target Platform**: macOS 26 and later.

**Performance Goals**: no call to the spelling checker for the 15,000 most frequent
words of a language. A call for an unknown word takes from 10 to 70 milliseconds.

**Constraints**: the typed text stays in memory. The spelling checker is a system service on
the same Mac.

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The word goes to the system spelling checker on this Mac only. |
| II. Keep the text of the user safe | Pass. A double Shift tap reverts the correction and makes an exception. |
| III. Detection is a pure, tested library | Pass. The rules are in `KeySwitchCore` with tests. The checker call is in the app. |
| IV. Native, small, free of dependencies | Pass. |
| V. Spec first | Pass. |

## Project Structure

```text
specs/003-typo-correction/
  spec.md  plan.md  research.md  data-model.md  quickstart.md  tasks.md

Sources/KeySwitchCore/
  TypoPolicy.swift      which words to examine, which corrections to accept
  Detector.swift        rank(of:language:) for the frequency checks
  WordBuffer.swift      typoCorrected state
Sources/KeySwitch/
  SpellCorrector.swift  call to NSSpellChecker
  Engine.swift          correction on Space and Return, revert on double Shift
  Settings.swift        fixTypos
  Views/SettingsView.swift  the switch
  SelfTest.swift        scenarios
Tests/KeySwitchCoreTests/TypoPolicyTests.swift
```

**Structure Decision**: the same two targets as feature 001. The contracts folder is absent,
because all interfaces of the app are internal.

## Complexity Tracking

No violations.
