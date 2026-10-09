# Tasks: Selected text

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: Foundation <!-- slop: heading of the spec-kit template -->

- [x] T001 Add `LayoutConverter` in `Sources/KeySwitchCore/LayoutConverter.swift`, with tests
- [x] T002 Add the Accessibility read and the clipboard copy and paste in `Sources/KeySwitch/Selection.swift`
- [x] T003 Add the `selectionGestures` setting, its switch and its Russian text

## Phase 2: User Story 1, layout of the selection (P1)

- [x] T004 [US1] Convert the selection on a double Shift tap with an empty buffer in `Sources/KeySwitch/Engine.swift`
- [x] T005 [US1] Bring the text back on a second gesture
- [x] T006 [US1] Add the selection scenarios and the clipboard check to `Sources/KeySwitch/SelfTest.swift`

## Phase 3: User Story 2, case of the selection (P2)

- [x] T007 [US2] Change the case of the selection on a double Option tap in `Sources/KeySwitch/Engine.swift`
- [x] T008 [US2] Add the case scenarios to `Sources/KeySwitch/SelfTest.swift`

## Phase 4: Delivery

- [x] T009 Run `swift test` and the end-to-end test
- [x] T010 Describe the selection gestures in `README.md`
- [ ] T011 Check the gestures by hand in a browser and in an Electron app. The end-to-end test uses a native text view only.
