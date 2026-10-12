# Implementation Plan: Search in the clipboard history

**Branch**: `014-clipboard-search` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

The event tap takes Control-Option-V and opens a floating panel. The panel has a SwiftUI
search field and a list. The search rule is a pure function of `ClipboardHistory`. A selected
entry goes through the same path as a click in the menu, and then the app posts Command-V.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: AppKit (`NSPanel`), SwiftUI.

**Storage**: `UserDefaults`: one new key, `clipboardSearch`.

**Testing**: Swift Testing for the search rule. The end-to-end test opens the panel with the
shortcut and sets the search text in the model of the panel.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| Shortcut | Control-Option-V, fixed | Command-Shift-V is the plain paste. A recorder for shortcuts is a feature of its own |
| Window | A panel that does not activate the app | The front app keeps the focus, so Command-V goes to it |
| Search rule | Each word of the query is in the text, with no regard to case and diacritics | Simple and fast for 100 entries. Fuzzy search gives surprises |
| Images | Only with an empty query | An image has no text |
| Keys in the panel | The engine ignores them while the panel is open | The detector must not convert the search text |
| After the selection | Clipboard, then Command-V after a short wait | The panel must be closed before the paste |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The search text stays in memory. |
| II. Keep the text of the user safe | Pass. The paste is the decision of the user. |
| III. Detection is a pure, tested library | Pass. The search rule is in `KeySwitchCore` with tests. |
| IV. Native, small, free of dependencies | Pass. |
| V. Spec first | Pass. |

## Project Structure

```text
Sources/KeySwitchCore/
  ClipboardHistory.swift     search
Sources/KeySwitch/
  ClipboardSearch.swift      panel, model, view
  Engine.swift               shortcut, pause while the panel is open
  Settings.swift             clipboardSearch
  SelfTest.swift             scenarios
  Views/SettingsView.swift   switch
Tests/KeySwitchCoreTests/
  ClipboardHistoryTests.swift
```
