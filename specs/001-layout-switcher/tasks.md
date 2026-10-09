# Tasks: Layout switcher

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: Setup <!-- slop: heading of the spec-kit template -->

- [x] T001 Create the Swift package with the `KeySwitchCore` and `KeySwitch` targets in `Package.swift`
- [x] T002 Add `Scripts/make-wordlists.py` and generate `Resources/ru.txt` and `Resources/en.txt`
- [x] T003 Add `Scripts/build-app.sh` that assembles and signs `KeySwitch.app`

## Phase 2: Foundation

- [x] T004 Implement `LanguageModel` (dictionary, ranks, trigram score) in `Sources/KeySwitchCore/LanguageModel.swift`
- [x] T005 Implement `WordBuffer` in `Sources/KeySwitchCore/WordBuffer.swift` with tests
- [x] T006 Implement `InputSources` (list, select, translate) in `Sources/KeySwitch/InputSources.swift`
- [x] T007 Implement `Typist` (Backspace and Unicode text) in `Sources/KeySwitch/Typist.swift`

## Phase 3: User Story 1, Shift tap (P1)

- [x] T008 [US1] Implement `ShiftTapRecognizer` in `Sources/KeySwitchCore/ShiftTapRecognizer.swift` with tests
- [x] T009 [US1] Implement the event tap in `Sources/KeySwitch/Engine.swift` and select the next layout on a tap

## Phase 4: User Story 2, double Shift tap (P1)

- [x] T010 [US2] Convert the word buffer on a double tap in `Sources/KeySwitch/Engine.swift`
- [x] T011 [US2] Reset the buffer on caret movement, shortcuts, mouse clicks and app changes

## Phase 5: User Story 3, automatic switching (P2)

- [x] T012 [US3] Implement `Detector` in `Sources/KeySwitchCore/Detector.swift`
- [x] T013 [US3] Add accuracy tests on held-out words that enforce SC-001, SC-002 and SC-003
- [x] T014 [US3] Evaluate the word on Space and Return in `Sources/KeySwitch/Engine.swift`
- [x] T015 [US3] Remember a reverted word as an exception

## Phase 6: User Story 4, menu bar app (P3)

- [x] T016 [US4] Add the SwiftUI app with `MenuBarExtra` and the Settings scene
- [x] T017 [US4] Add the onboarding window for the Accessibility permission
- [x] T018 [US4] Add the per-app exclusion and start at login

## Phase 7: Delivery

- [x] T019 Add `README.md`, `LICENSE` and the data notice
- [x] T020 Add the CI workflow in `.github/workflows/ci.yml`
- [x] T021 Add release-please and the release build in `.github/workflows/release.yml`
- [x] T022 Create the public GitHub repository and push
- [ ] T023 Check the app by hand in a real text field: US1, US2 and US3 scenarios

## Dependencies

- Phase 2 blocks all user stories.
- US2 needs US1. US3 needs the buffer and the conversion from US2.
- Phase 7 needs a green build.
