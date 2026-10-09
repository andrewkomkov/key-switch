# Tasks: Typo correction

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: Foundation <!-- slop: heading of the spec-kit template -->

- [x] T001 Add `TypoPolicy` (candidate, edit distance, acceptance) in `Sources/KeySwitchCore/TypoPolicy.swift`
- [x] T002 [P] Add tests for `TypoPolicy` in `Tests/KeySwitchCoreTests/TypoPolicyTests.swift`
- [x] T003 [P] Add `rank(of:language:)` to `Sources/KeySwitchCore/Detector.swift` with a test
- [x] T004 Add the `typoCorrected` state to `Sources/KeySwitchCore/WordBuffer.swift` with tests
- [x] T005 [P] Add the `fixTypos` setting, default false, in `Sources/KeySwitch/Settings.swift`

## Phase 2: User Story 1, a typo corrects itself (P1)

**Independent test**: with the option on, `recieve` and Space give `receive `.

- [x] T006 [US1] Add `SpellCorrector` with the `NSSpellChecker` call in `Sources/KeySwitch/SpellCorrector.swift`
- [x] T007 [US1] Correct the word on Space and Return in `Sources/KeySwitch/Engine.swift`, after the layout detector
- [x] T008 [US1] Add the switch and its Russian text in `Sources/KeySwitch/Views/SettingsView.swift` and `Resources/ru.lproj/Localizable.strings`

## Phase 3: User Story 2, double Shift reverts (P1)

**Independent test**: after a correction, two Shift taps give `recieve ` in the same layout.

- [x] T009 [US2] Revert the typo correction on a double Shift tap in `Sources/KeySwitch/Engine.swift`
- [x] T010 [US2] Add the reverted word to the exceptions and skip exception words

## Phase 4: User Story 3, technical words stay (P2)

**Independent test**: 30 technical words, names and abbreviations stay as typed.

- [x] T011 [US3] Add a test with 30 technical words in `Tests/KeySwitchCoreTests/TypoPolicyTests.swift` against the system spelling checker

## Phase 5: Delivery

- [x] T012 Add the typo scenarios to `Sources/KeySwitch/SelfTest.swift`
- [x] T013 Run `swift test` and the end-to-end test from [quickstart.md](quickstart.md)
- [x] T014 Describe the option in `README.md`
- [ ] T015 Check the switch in the settings window by hand. No test opens that window.

## Dependencies

- Phase 1 blocks the user stories.
- US2 needs US1. US3 needs US1.
- T002, T003 and T005 touch different files and can go in parallel.

## Implementation strategy

US1 and US2 together are the smallest useful increment: a correction with no revert breaks
principle II of the constitution.
