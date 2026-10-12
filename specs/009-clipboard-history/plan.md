# Implementation Plan: Clipboard history

**Branch**: `009-clipboard-history` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

A pure type in `KeySwitchCore` holds the ordered list and its rules. A monitor in the app
reads the change count of the clipboard on a timer and makes entries. It saves the list to
a folder in Application Support. The menu bar menu and a new settings tab show the entries.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: none new.

**Storage**: `UserDefaults`: `clipboardHistory` and `clipboardLimit`. The folder
`~/Library/Application Support/KeySwitch/Clipboard` has `history.json` and one PNG file for
each image entry. The folder has mode 700 and the files have mode 600.

**Testing**: Swift Testing for the list rules and the JSON form. The end-to-end test writes
to the real clipboard and uses a temporary folder.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| How does the app see a copy? | A timer reads the change count each 0.5 seconds | macOS has no notification for the clipboard |
| Where is the list? | One JSON file, written again after each change | 100 entries are small. A database is not necessary |
| Where is an image? | A PNG file, named by the identifier of the entry | The JSON file stays small |
| Text and image in one item | Text entry | Office apps add a picture of the text to each copy |
| Default of the switch | Off | The option writes copied content to the disk |
| The switch goes to off | The app stops the timer and keeps the list | Only "Clear History" deletes data |
| Entries in the menu | 15 in the menu, the others in a submenu | A long menu is hard to use |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Needs an amendment. The history puts copied content on the disk. Version 1.2.0 adds this exception, only with the option on. Keystrokes stay in memory as before. |
| II. Keep the text of the user safe | Pass. A click replaces the clipboard, and the replaced item is already in the history. |
| III. Detection is a pure, tested library | Pass. The list rules are in `KeySwitchCore` with tests. |
| IV. Native, small, free of dependencies | Pass. |
| V. Spec first | Pass. |

## Project Structure

```text
Sources/KeySwitchCore/
  ClipboardHistory.swift     entries, order, limit, menu title
Sources/KeySwitch/
  ClipboardMonitor.swift     timer, clipboard read and write, files
  Selection.swift            mark for the changes of the app
  Settings.swift             clipboardHistory, clipboardLimit
  SelfTest.swift             scenarios
  Views/MenuView.swift       entries in the menu
  Views/SettingsView.swift   "Clipboard" tab
Tests/KeySwitchCoreTests/
  ClipboardHistoryTests.swift
```
