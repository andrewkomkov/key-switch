# Feature Specification: Text replacements of macOS in all apps

**Feature Branch**: `012-system-replacements`

**Created**: 2026-10-12

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "Autoreplace (snippets): my list of shortcuts." The user said:
"3 - это ж есть в макоси - мб как-то засинхронь".

## User scenarios and tests

### User Story 1: A shortcut works in each app (Priority: P1)

The user has the shortcut `итд` for "и так далее" in System Settings, Keyboard, Text
Replacements. macOS applies the list in Notes and in Safari. A browser on Chromium, an
Electron app and a terminal ignore the list. With this feature, the user types `итд` and
Space in such an app and gets the phrase.

**Why this priority**: The user has one list, in the system. The list must work in each app.

**Independent Test**: Add the shortcut `omw` for `On my way!` in System Settings. Type
`omw` and Space in an Electron app. The text is `On my way! `.

**Acceptance Scenarios**:

1. The option is on. If the user types a shortcut and presses Space or Return, the phrase
   replaces the shortcut.
2. If the user then taps Shift two times, the shortcut comes back and becomes an exception.
3. If the user types an exception, the text stays as typed.
4. If the user types the shortcut with a capital first letter, the phrase gets a capital
   first letter.
5. The user types the shortcut, then `,` or `.`, then Space. The phrase replaces the
   shortcut, and the mark stays.
6. The option is off. If the user types a shortcut, the text stays as typed.
7. The front app is in the list of excluded apps. The text stays as typed.

### User Story 2: The list stays in the system (Priority: P2)

The user adds, changes or removes a shortcut in System Settings. KeySwitch uses the new
list. KeySwitch has no list of its own.

**Acceptance Scenarios**:

1. If the user adds a shortcut in System Settings, KeySwitch applies it not later than 10
   seconds after that.
2. The settings of KeySwitch show the number of shortcuts and a button that opens the
   keyboard settings of macOS.

### Edge cases

- In an app where macOS applies the list, KeySwitch replaces the shortcut first. The text
  gets the phrase one time.
- A shortcut with a space in it cannot match one word. KeySwitch ignores it.
- A phrase with a line break can send a message in a chat app. KeySwitch ignores it.
- An entry where the phrase is the same as the shortcut does nothing.
- A shortcut is also the incorrect-layout form of a word. The shortcut wins.
- The iCloud list changes on a different device. macOS brings the change to this Mac, and
  KeySwitch reads it there.

## Requirements

### Functional requirements

- **FR-001**: With the option on, the app MUST replace a completed word that is a shortcut
  of the macOS list with its phrase.
- **FR-002**: The app MUST read the list from macOS and MUST NOT keep a copy on the disk.
- **FR-003**: A double Shift tap MUST bring the shortcut back and make it an exception.
- **FR-004**: The app MUST ignore a shortcut with white space and a phrase with a line break.
- **FR-005**: The settings MUST have a switch for the option. The default MUST be on.
- **FR-006**: The settings MUST show the number of shortcuts and open the macOS list.

### Key entities

- **Replacement**: a shortcut and its phrase, from the macOS list.

## Success criteria

### Measurable outcomes

- **SC-001**: The unit tests pass for the match rules.
- **SC-002**: The end-to-end test passes with the scenarios of this feature.
- **SC-003**: All scenarios of features 001 to 011 pass as before.

## Assumptions

- macOS keeps the list in the global preferences, in `NSUserDictionaryReplacementItems`.
  An app without a sandbox can read this key.
- The user has the shortcuts on purpose, so the default is on.
