# Tasks: Capital letter at the start of a sentence

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: Foundation <!-- slop: heading of the spec-kit template -->

- [x] T001 Add `SentenceCase` in `Sources/KeySwitchCore/SentenceCase.swift`, with tests
- [x] T002 Give the keys of the previous word in `Sources/KeySwitchCore/WordBuffer.swift`, with tests
- [x] T003 Add the `capitalizeSentences` setting in `Sources/KeySwitch/Settings.swift`

## Phase 2: User Story 1, the word after a full stop (P1)

- [x] T004 [US1] Apply the rule to the completed word in `Sources/KeySwitch/Engine.swift`
- [x] T005 [US1] Apply the rule after a layout conversion, a capital correction and a typo correction
- [x] T006 [US1] Add the switch in `Sources/KeySwitch/Views/SettingsView.swift` and the Russian texts

## Phase 3: Delivery

- [x] T007 Add the scenarios to `Sources/KeySwitch/SelfTest.swift`
- [x] T008 Run `swift test`
- [ ] T009 Run the end-to-end test
- [x] T010 Describe the option in `README.md`
- [ ] T011 Check by hand one day of usual work with the option on: messengers, a browser, a terminal
