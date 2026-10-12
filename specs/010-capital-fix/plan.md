# Implementation Plan: Correction of accidental capitals

**Branch**: `010-capital-fix` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

A new pure type in `KeySwitchCore`, `CaseFixer`, finds the two case patterns and gives the
corrected word. The engine asks it for each completed word and for each word that the
detector converts. The change uses the same state as a typo correction, so the double Shift
tap reverts it.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: none new.

**Storage**: `UserDefaults`: one new key, `fixCapitals`.

**Testing**: Swift Testing for the patterns. The end-to-end test for the typed word, the
revert, the exception and the converted word.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| Which words does the app change? | Only a word that the dictionary or the learned list has | `OSes` and `МВт` are not dictionary words, so they stay |
| Short words | 3 letters with `s` at the end stay | `IDs` and `TVs` are correct, and `tvs` is a dictionary word |
| Inverted pattern | 4 letters or more | `iOS` stays |
| Caps Lock state | No change | On a Mac, Caps Lock with Shift gives a capital. The key is not the cause |
| How does the user revert? | The state of the typo correction | One gesture for each automatic change, and an exception after it |
| Default of the switch | On | Two capitals at the start of a dictionary word are an error |
| Order at the end of a word | Layout, then capitals, then typos, then `ё` | A typo correction ignores a word with capitals in it |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The word stays in memory. Only a reverted word goes to the exceptions. |
| II. Keep the text of the user safe | Pass. A double Shift tap reverts the change, and the word becomes an exception. |
| III. Detection is a pure, tested library | Pass. `CaseFixer` is in `KeySwitchCore` with tests. |
| IV. Native, small, free of dependencies | Pass. The check is one dictionary read. |
| V. Spec first | Pass. |

## Project Structure

```text
Sources/KeySwitchCore/
  CaseFixer.swift            the two patterns
Sources/KeySwitch/
  Engine.swift               completed word, converted word
  Settings.swift             fixCapitals
  SelfTest.swift             scenarios
  Views/SettingsView.swift   switch
Tests/KeySwitchCoreTests/
  CaseFixerTests.swift
```
