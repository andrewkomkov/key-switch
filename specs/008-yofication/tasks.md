# Tasks: The letter ё

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: Foundation <!-- slop: heading of the spec-kit template -->

- [x] T001 Add `Resources/ru-yo.txt` with its license file, and name the source in `Resources/NOTICE.md`
- [x] T002 Add `Yoficator` in `Sources/KeySwitchCore/Yoficator.swift`, with tests
- [x] T003 Add the `yofication` setting in `Sources/KeySwitch/Settings.swift`
- [x] T004 Copy the dictionary into the app in `Scripts/build-app.sh`

## Phase 2: User Story 1, completed word (P1)

- [x] T005 [US1] Change the completed word and keep the revert state in `Sources/KeySwitch/Engine.swift`
- [x] T006 [US1] Add the switch in `Sources/KeySwitch/Views/SettingsView.swift` and the Russian texts

## Phase 3: User Story 2, converted word (P2)

- [x] T007 [US2] Apply the list to the automatic and the manual conversion in `Sources/KeySwitch/Engine.swift`

## Phase 4: Delivery

- [x] T008 Add the scenarios to `Sources/KeySwitch/SelfTest.swift`
- [x] T009 Run `swift test` and the end-to-end test
- [x] T010 Describe the option in `README.md`
- [ ] T011 Check the switch in the settings window by hand. The test sets the option in code.
