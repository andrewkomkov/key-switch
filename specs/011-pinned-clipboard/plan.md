# Implementation Plan: Pinned clipboard entries

**Branch**: `011-pinned-clipboard` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

`ClipboardEntry` gets a pin flag. The rules of `ClipboardHistory` for the limit and for the
clear function skip a pinned entry. The menu shows the pinned entries in their own group.
The user changes the pin with an Option-click in the menu or with a button in the settings.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: none new.

**Storage**: `history.json` gets one new field for each entry, `pinned`. A file without the
field stays valid.

**Testing**: Swift Testing for the list rules and the old JSON form. The end-to-end test
changes the pin through the monitor, not through the menu.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| Where is the pin? | A field of the entry | One list and one file, as before |
| Do pinned entries count for the limit? | No | The limit is for the flow of copies. The user selects the pinned entries one by one |
| "Clear History" | Keeps the pinned entries | The pinned entries are templates. The remove button deletes one of them |
| Gesture in the menu | Option-click | The menu is a standard menu. It has no second button for an item |
| Order of the pinned group | The order of the list: the last used entry first | No new sort rule |
| Old file | A missing field means not pinned | Version 0.5.0 wrote files without it |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The storage is the same as in feature 009. The user can see and remove each entry. |
| II. Keep the text of the user safe | Pass. A pin does not change the clipboard. |
| III. Detection is a pure, tested library | Pass. The list rules are in `KeySwitchCore` with tests. |
| IV. Native, small, free of dependencies | Pass. |
| V. Spec first | Pass. |

## Project Structure

```text
Sources/KeySwitchCore/
  ClipboardHistory.swift     pin flag, limit, clear
Sources/KeySwitch/
  ClipboardMonitor.swift     pin change
  SelfTest.swift             scenarios
  Views/MenuView.swift       "Pinned" group, Option-click
  Views/SettingsView.swift   pin button
Tests/KeySwitchCoreTests/
  ClipboardHistoryTests.swift
```
