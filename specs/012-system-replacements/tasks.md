# Tasks: Text replacements of macOS in all apps

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: Foundation <!-- slop: heading of the spec-kit template -->

- [x] T001 Add `TextReplacements` in `Sources/KeySwitchCore/TextReplacements.swift`, with tests
- [x] T002 Add the `systemReplacements` setting in `Sources/KeySwitch/Settings.swift`

## Phase 2: User Story 1, a shortcut works in each app (P1)

- [x] T003 [US1] Read the macOS list in `Sources/KeySwitch/SystemReplacements.swift`
- [x] T004 [US1] Replace the completed shortcut and keep the revert state in `Sources/KeySwitch/Engine.swift`

## Phase 3: User Story 2, the list stays in the system (P2)

- [x] T005 [US2] Read the list again after 5 seconds in `Sources/KeySwitch/SystemReplacements.swift`
- [x] T006 [US2] Add the switch, the count and the button in `Sources/KeySwitch/Views/SettingsView.swift`, with the Russian texts

## Phase 4: Delivery

- [x] T007 Add the scenarios to `Sources/KeySwitch/SelfTest.swift`
- [x] T008 Run `swift test`
- [ ] T009 Run the end-to-end test
- [x] T010 Describe the option in `README.md`
- [ ] T011 Check by hand that the app reads the real list of this Mac
- [ ] T012 Check by hand a shortcut in a Chromium browser, an Electron app and a terminal
- [ ] T013 Check by hand that Notes gets the phrase one time
