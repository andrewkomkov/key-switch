# Implementation Plan: Menu item for the clipboard search

**Branch**: `017-search-menu-item` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

The clipboard part of the menu gets one button. The button calls `ClipboardSearch.shared.show()`,
the same function that the shortcut calls.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: SwiftUI.

**Storage**: None.

**Testing**: The end-to-end test cannot click a menu item. A manual check is necessary.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| Position | The first item of the clipboard part | The user sees it before the long list of entries |
| Shortcut text | `keyboardShortcut` on the button | The menu shows the keys in the standard position |
| Search option off | The item stays, without the shortcut | The option is a switch for the shortcut only |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. No new data. |
| II. Keep the text of the user safe | Pass. The item only opens the panel. |
| III. Detection is a pure, tested library | Pass. No change in the library. |
| IV. Native, small, free of dependencies | Pass. |
| V. Spec first | Pass. |

## Project Structure

```text
Sources/KeySwitch/
  Views/MenuView.swift             button
Resources/ru.lproj/
  Localizable.strings              Russian text
README.md                          second way to open the panel
```
