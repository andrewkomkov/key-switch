# Tasks: Pinned clipboard entries

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: User Story 1, a pinned entry stays (P1)

- [x] T001 [US1] Add the pin flag and the new rules in `Sources/KeySwitchCore/ClipboardHistory.swift`, with tests
- [x] T002 [US1] Read a history file without pin data, with a test
- [x] T003 [US1] Add the pin change in `Sources/KeySwitch/ClipboardMonitor.swift`
- [x] T004 [US1] Show the "Pinned" group in `Sources/KeySwitch/Views/MenuView.swift`

## Phase 2: User Story 2, menu and settings (P2)

- [x] T005 [US2] Change the pin on an Option-click in `Sources/KeySwitch/Views/MenuView.swift`
- [x] T006 [US2] Add the pin button in `Sources/KeySwitch/Views/SettingsView.swift` and the Russian texts

## Phase 3: Delivery

- [x] T007 Add the scenarios to `Sources/KeySwitch/SelfTest.swift`
- [x] T008 Run `swift test`
- [ ] T009 Run the end-to-end test
- [x] T010 Describe the pin in `README.md`
- [ ] T011 Check the Option-click in the menu and the pin button in the settings by hand
