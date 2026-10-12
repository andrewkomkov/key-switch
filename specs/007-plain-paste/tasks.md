# Tasks: Paste without formatting

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: User Story 1, plain paste (P1)

- [x] T001 [US1] Add the `plainPaste` setting in `Sources/KeySwitch/Settings.swift`
- [x] T002 [US1] Handle Command-Shift-V in `Sources/KeySwitch/Engine.swift`
- [x] T003 [US1] Add the switch in `Sources/KeySwitch/Views/SettingsView.swift` and the Russian texts

## Phase 2: Delivery

- [x] T004 Add the paste scenarios to `Sources/KeySwitch/SelfTest.swift`
- [x] T005 Run `swift test` and the end-to-end test
- [x] T006 Describe the shortcut in `README.md`
- [ ] T007 Check the shortcut by hand in a browser, in an Electron app and in an office app
