# Tasks: Emoji codes

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: Foundation <!-- slop: heading of the spec-kit template -->

- [x] T001 Add `Resources/emoji.txt` with its license file and `Scripts/make-emoji-list.py`, and name the source in `Resources/NOTICE.md`
- [x] T002 Add `EmojiCodes` in `Sources/KeySwitchCore/EmojiCodes.swift`, with tests
- [x] T003 Add the `emojiCodes` setting in `Sources/KeySwitch/Settings.swift`
- [x] T004 Copy the list into the app in `Scripts/build-app.sh`

## Phase 2: User Story 1, a code becomes an emoji (P1)

- [x] T005 [US1] Replace the completed code and keep the revert state in `Sources/KeySwitch/Engine.swift`
- [x] T006 [US1] Read the keys in the English layout if the typed text is not a code
- [x] T007 [US1] Add the switch in `Sources/KeySwitch/Views/SettingsView.swift` and the Russian texts

## Phase 3: Delivery

- [x] T008 Add the scenarios to `Sources/KeySwitch/SelfTest.swift`
- [x] T009 Run `swift test`
- [ ] T010 Run the end-to-end test
- [x] T011 Describe the option in `README.md`
- [ ] T012 Check by hand an emoji and its revert in a Chromium browser and an Electron app
