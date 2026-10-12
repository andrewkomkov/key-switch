# Implementation Plan: Emoji codes

**Branch**: `015-emoji-codes` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

A new pure type in `KeySwitchCore`, `EmojiCodes`, reads a list of codes and gives the emoji
for a typed word of the form `:name:`. The engine asks it at the end of each word, after the
text replacements and before the layout detector. The change uses the same state as a typo
correction, so the double Shift tap reverts it.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: none new. One new data file, `Resources/emoji.txt`.

**Storage**: `UserDefaults`: one new key, `emojiCodes`.

**Testing**: Swift Testing for the format and the full list. The end-to-end test for the
typed code, the revert and the code from the other layout.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| Source of the codes | `db/emoji.json` of github/gemoji, MIT license | The codes of GitHub. Slack and Discord use almost the same names |
| Format of the file | One line for each code: the code, a tab, the emoji | 35 KB. The app needs no JSON parser for it |
| Other layout | If the typed text is not a code, the app reads the same keys in the English layout | The colon is on a different key in the Russian layout |
| Order at the end of a word | Text replacement, emoji code, layout, capitals, typos, `ё` | A code is an exact match. The detector guesses |
| How does the user revert? | The state of the typo correction | One gesture for each automatic change |
| Default of the switch | On | The form `:name:` is rare in usual text |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The list is in the app. The word stays in memory. |
| II. Keep the text of the user safe | Pass. A double Shift tap reverts the change. |
| III. Detection is a pure, tested library | Pass. `EmojiCodes` is in `KeySwitchCore` with tests. |
| IV. Native, small, free of dependencies | Pass. One dictionary read for each word. |
| V. Spec first | Pass. |

## Project Structure

```text
Resources/
  emoji.txt                  codes
  emoji.LICENSE.txt          license of gemoji
Scripts/
  make-emoji-list.py         makes emoji.txt from the gemoji file
  build-app.sh               copies the two files
Sources/KeySwitchCore/
  EmojiCodes.swift
Sources/KeySwitch/
  Engine.swift, Settings.swift, SelfTest.swift, Views/SettingsView.swift
Tests/KeySwitchCoreTests/
  EmojiCodesTests.swift
```
