# Implementation Plan: Selected text

**Branch**: `005-selection` | **Date**: 2026-10-09 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

When the phrase buffer is empty, the double Shift tap and the double Option tap work on the
selected text. The app reads the selection through the Accessibility API. If the front app
gives no answer, the app copies the selection through the clipboard. The app writes the
result with a paste and then restores the clipboard.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: ApplicationServices (`AXUIElement`), AppKit (`NSPasteboard`).

**Storage**: `UserDefaults`: one new key, `selectionGestures`.

**Testing**: Swift Testing for the character conversion. The end-to-end test for the two
read paths and for the clipboard.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| Gesture | The gestures of features 001 and 004, when the buffer is empty | No new shortcut to learn |
| Read | Accessibility first, clipboard second | Accessibility leaves the clipboard alone. Electron and Java apps need the clipboard |
| Write | Paste | Typed line ends send the message in a chat app |
| No selection | Stop when a text field reports an empty selection | A copy with no selection takes the full line in some editors |
| Direction | The layout that owns more letters of the text is the source | The selection can be in the active layout or in the other one |
| Second gesture | Delete the inserted text and paste again | The paste removes the selection |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The text stays in memory. The paste data has the transient mark for clipboard managers. |
| II. Keep the text of the user safe | Pass. The same gesture brings the text back. The clipboard gets its content back. |
| III. Detection is a pure, tested library | Pass. `LayoutConverter` is in `KeySwitchCore` with tests. |
| IV. Native, small, free of dependencies | Pass. |
| V. Spec first | Pass. |

## Project Structure

```text
Sources/KeySwitchCore/LayoutConverter.swift   characters of one layout to the other
Sources/KeySwitch/
  Selection.swift    read through Accessibility, copy and paste through the clipboard
  Engine.swift       selection branch of the two gestures
  Settings.swift     selectionGestures
  SelfTest.swift     scenarios
Tests/KeySwitchCoreTests/LayoutConverterTests.swift
```
