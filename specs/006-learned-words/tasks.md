# Tasks: Learned words

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: Foundation <!-- slop: heading of the spec-kit template -->

- [x] T001 Amend principle I in `.specify/memory/constitution.md` and set the version to 1.1.0
- [x] T002 Add `WordLearner` in `Sources/KeySwitchCore/WordLearner.swift`, with tests
- [x] T003 Add learned words and `isLearnable` to `Sources/KeySwitchCore/Detector.swift`, with tests
- [x] T004 Add the `learnWords` and `learnedWords` settings in `Sources/KeySwitch/Settings.swift`

## Phase 2: User Story 1, frequent words (P1)

- [x] T005 [US1] Count the completed word in `Sources/KeySwitch/Engine.swift`
- [x] T006 [US1] Add the switch, the list of learned words and the Russian texts

## Phase 3: User Story 2, manual conversion (P1)

- [x] T007 [US2] Learn the result of a manual conversion and forget the original reading in `Sources/KeySwitch/Engine.swift`

## Phase 4: Delivery

- [x] T008 Add the learning scenarios to `Sources/KeySwitch/SelfTest.swift`
- [x] T009 Run `swift test` and the end-to-end test
- [x] T010 Describe learning and its privacy effect in `README.md`
- [ ] T011 Check the switch and the "Learned" tab in the settings window by hand. The test sets the option in code.
