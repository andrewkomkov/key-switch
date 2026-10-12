# Tasks: Search in the clipboard history

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: User Story 1, search with the keyboard (P1)

- [x] T001 [US1] Add the search rule in `Sources/KeySwitchCore/ClipboardHistory.swift`, with tests
- [x] T002 [US1] Add the `clipboardSearch` setting in `Sources/KeySwitch/Settings.swift`
- [x] T003 [US1] Add the panel, its model and its view in `Sources/KeySwitch/ClipboardSearch.swift`
- [x] T004 [US1] Take Control-Option-V and ignore the keys while the panel is open in `Sources/KeySwitch/Engine.swift`
- [x] T005 [US1] Add the switch in `Sources/KeySwitch/Views/SettingsView.swift` and the Russian texts

## Phase 2: Delivery

- [x] T006 Add the scenarios to `Sources/KeySwitch/SelfTest.swift`
- [x] T007 Run `swift test`
- [ ] T008 Run the end-to-end test
- [x] T009 Describe the search in `README.md`
- [ ] T010 Check by hand the look of the panel, the arrow keys, Escape and a click out of the panel
- [ ] T011 Check by hand the paste into a different app: the front app must stay active
