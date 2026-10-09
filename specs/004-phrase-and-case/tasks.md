# Tasks: Phrase conversion and case change

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: Foundation <!-- slop: heading of the spec-kit template -->

- [x] T001 Replace `ShiftTapRecognizer` with `TapRecognizer` in `Sources/KeySwitchCore/TapRecognizer.swift`, with tests
- [x] T002 Keep the phrase and the span in `Sources/KeySwitchCore/WordBuffer.swift`, with tests

## Phase 2: User Story 1, more words (P1)

- [x] T003 [US1] Extend the conversion on a repeated Shift tap in `Sources/KeySwitch/Engine.swift`
- [x] T004 [US1] Add the phrase scenarios to `Sources/KeySwitch/SelfTest.swift`

## Phase 3: User Story 2, case (P2)

- [x] T005 [P] [US2] Add `CaseCycler` in `Sources/KeySwitchCore/CaseCycler.swift`, with tests
- [x] T006 [US2] Add `replaceWord` to `Sources/KeySwitchCore/WordBuffer.swift`, with tests
- [x] T007 [US2] Change the case on a double Option tap in `Sources/KeySwitch/Engine.swift`
- [x] T008 [US2] Add the `caseGesture` setting, its switch and its Russian text
- [x] T009 [US2] Add the case scenarios to `Sources/KeySwitch/SelfTest.swift`

## Phase 4: Delivery

- [x] T010 Run `swift test` and the end-to-end test
- [x] T011 Describe the two gestures in `README.md`
