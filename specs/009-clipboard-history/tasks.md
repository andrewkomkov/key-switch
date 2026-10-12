# Tasks: Clipboard history

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: Foundation <!-- slop: heading of the spec-kit template -->

- [x] T001 Amend principle I in `.specify/memory/constitution.md` and set the version to 1.2.0
- [x] T002 Add `ClipboardHistory` in `Sources/KeySwitchCore/ClipboardHistory.swift`, with tests
- [x] T003 Add the `clipboardHistory` and `clipboardLimit` settings in `Sources/KeySwitch/Settings.swift`

## Phase 2: User Story 1, text in the menu (P1)

- [x] T004 [US1] Add `ClipboardMonitor` in `Sources/KeySwitch/ClipboardMonitor.swift`: timer, text entries, ignored items
- [x] T005 [US1] Mark the clipboard changes of the app in `Sources/KeySwitch/Selection.swift`
- [x] T006 [US1] Show the entries and "Clear History" in `Sources/KeySwitch/Views/MenuView.swift`
- [x] T007 [US1] Add the "Clipboard" tab in `Sources/KeySwitch/Views/SettingsView.swift` and the Russian texts

## Phase 3: User Story 2, images (P2)

- [x] T008 [US2] Keep image entries as PNG files and show a small picture in the menu

## Phase 4: User Story 3, restart (P2)

- [x] T009 [US3] Save the list to `history.json` and read it at the start

## Phase 5: Delivery

- [x] T010 Add the scenarios to `Sources/KeySwitch/SelfTest.swift`
- [x] T011 Run `swift test` and the end-to-end test
- [x] T012 Describe the history and its privacy effect in `README.md`
- [ ] T013 Check the menu, the small pictures and the "Clipboard" tab by hand
- [ ] T014 Check by hand if macOS asks for permission to read the clipboard
