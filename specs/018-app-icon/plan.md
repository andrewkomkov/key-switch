# Implementation Plan: New icon

**Branch**: `018-app-icon` | **Date**: 2026-10-13 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

The app draws the menu bar icon in code: a key with the letters `Aя`. The icon script
draws the same letters on the app icon. The repository gets a PNG copy of the app icon for
the README.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: AppKit (`NSImage` with a drawing handler).

**Storage**: None.

**Testing**: A look at the rendered images. The end-to-end test as a regression check.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| Symbol | A key with `Aя` | One Latin and one Cyrillic letter show the two languages. No SF Symbol has this pair |
| Source of the menu bar image | A drawing handler in code | Sharp at each scale, no image files in the bundle |
| On and off | Filled key with cut-out letters, and outline key | The same rule as `shift.fill` and `shift` before |
| App icon | The same gradient, the letters in place of the arrow | The two icons stay one family |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. No data. |
| II. Keep the text of the user safe | Pass. No change in the engine. |
| III. Detection is a pure, tested library | Pass. No change in the library. |
| IV. Native, small, free of dependencies | Pass. System fonts and AppKit only. |
| V. Spec first | Pass. |

## Project Structure

```text
Sources/KeySwitch/
  MenuBarIcon.swift          image for the two states
  KeySwitchApp.swift         label of the menu bar item
Scripts/
  make-icon.swift            new symbol, PNG copy for the README
Resources/AppIcon.icns       new icon
docs/icon.png                copy for the README
```
