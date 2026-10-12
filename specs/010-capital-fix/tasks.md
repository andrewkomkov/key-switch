# Tasks: Correction of accidental capitals

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: Foundation <!-- slop: heading of the spec-kit template -->

- [x] T001 Add `CaseFixer` in `Sources/KeySwitchCore/CaseFixer.swift`, with tests
- [x] T002 Add the `fixCapitals` setting in `Sources/KeySwitch/Settings.swift`

## Phase 2: User Story 1 and User Story 2, completed word (P1, P2)

- [x] T003 [US1] Change the completed word and keep the revert state in `Sources/KeySwitch/Engine.swift`
- [x] T004 [US1] Apply the rule to a word that the detector converts in `Sources/KeySwitch/Engine.swift`
- [x] T005 [US1] Add the switch in `Sources/KeySwitch/Views/SettingsView.swift` and the Russian text

## Phase 3: Delivery

- [x] T006 Add the scenarios to `Sources/KeySwitch/SelfTest.swift`
- [x] T007 Run `swift test`
- [ ] T008 Run the end-to-end test
- [x] T009 Describe the option in `README.md`
- [ ] T010 Check the switch in the settings window by hand. The test sets the option in code.
