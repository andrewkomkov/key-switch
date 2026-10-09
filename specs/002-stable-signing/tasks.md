# Tasks: Stable local signing

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: User Story 1, stable signature (P1)

- [x] T001 [US1] Add `Scripts/make-signing-identity.sh` and check the signature on a test file
- [x] T002 [US1] Sign with the local identity in `Scripts/build-app.sh` when it exists
- [x] T003 [US1] Check SC-001: a new build starts its event tap with no new permission

## Phase 2: User Story 2, exclusion test (P2)

- [x] T004 [US2] Use the app that gets the keys for the exclusion in `Sources/KeySwitch/Engine.swift`
- [x] T005 [US2] Add the exclusion scenario to `Sources/KeySwitch/SelfTest.swift` and run the test.
  Result: 17 scenarios pass.

## Phase 3: Delivery

- [x] T006 Describe the local identity in `README.md`
- [x] T007 Tick T018 of feature 001 after T005 passes
- [ ] T008 Check the start at login by hand. No test examined this control.
