# Implementation Plan: Paste without formatting

**Branch**: `007-plain-paste` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

The event tap sees Command-Shift-V and stops the event. The app keeps a copy of the
clipboard, puts only the plain text there, sends Command-V, and puts the copy back. Feature
005 already has these clipboard functions.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: none new.

**Storage**: `UserDefaults`: one new key, `plainPaste`.

**Testing**: The end-to-end test pastes bold text into a rich text view and reads the font.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| How does the text lose its format? | The clipboard gets the string type only, then Command-V | It works in each app. Menu commands for plain paste have different names and shortcuts |
| What if the clipboard has no text? | The event goes to the front app | The shortcut of the app keeps its function for images and files |
| Default of the switch | On | The user asked for the shortcut. Excluded apps keep their own shortcut |
| Where is the code? | `Engine` and `Selection` | The work is clipboard and events. There is no pure logic for `KeySwitchCore` |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The text of the clipboard stays in memory for the time of the paste. |
| II. Keep the text of the user safe | Pass. The clipboard gets its content back. |
| III. Detection is a pure, tested library | Pass. The detector does not change. |
| IV. Native, small, free of dependencies | Pass. |
| V. Spec first | Pass. |

## Project Structure

```text
Sources/KeySwitch/
  Engine.swift             shortcut and paste
  Settings.swift           plainPaste
  SelfTest.swift           scenarios
  Views/SettingsView.swift switch
Resources/ru.lproj/Localizable.strings
```
