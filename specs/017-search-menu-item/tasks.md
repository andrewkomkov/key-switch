# Tasks: Menu item for the clipboard search

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: User Story 1, search from the menu (P1)

- [x] T001 [US1] Add the button to the clipboard part of `Sources/KeySwitch/Views/MenuView.swift`
- [x] T002 [US1] Add the Russian text to `Resources/ru.lproj/Localizable.strings`

## Phase 2: Delivery

- [x] T003 Run `swift test`
- [x] T004 Run the end-to-end test
- [x] T005 Describe the menu item in `README.md`
- [x] T006 Click the item with an accessibility script. The panel opens, and the front app stays active
- [ ] T007 Check by hand the paste with Return after a click on the item
