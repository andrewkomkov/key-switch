# Feature Specification: Typo correction

**Feature Branch**: `003-typo-correction`

**Created**: 2026-10-09

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "Maybe also fix typos? macOS has dictionaries and it highlights
a word that is typed wrong. Make it a separate option that can be turned off, with the same
undo by double Shift."

## User scenarios and tests

### User Story 1: A typo corrects itself (Priority: P1)

The user sets the typo option to on. The user types a word with a typo and completes it
with Space or Return. KeySwitch replaces the word with the correct spelling. The layout
stays the same.

**Why this priority**: This is the feature. macOS corrects typos only in some apps. The
user gets the same help in each app.

**Independent Test**: Set the option to on. In the English layout, type `recieve` and Space.
The field shows `receive `.

**Acceptance Scenarios**:

1. The option is on and English is active. If the user types `recieve` and Space, the text
   becomes `receive ` and English stays active.
2. The option is on and Russian is active. If the user types `севодня` and Space, the text
   becomes `сегодня `.
3. The option is on. If the user types a correct word, the text stays the same.
4. The option is on. If the user types `Recieve,` and Space, the text becomes `Receive, `.
5. The option is off. If the user types `recieve` and Space, the text stays the same.

### User Story 2: Double Shift reverts a typo correction (Priority: P1)

KeySwitch corrected a word, but the user wanted the original spelling. The user taps Shift
two times. The original word comes back, the layout stays the same, and KeySwitch adds the
word to the exceptions.

**Why this priority**: The constitution tells that one gesture must revert each automatic
change.

**Independent Test**: After the test of story 1, tap Shift two times. The field shows
`recieve ` and English is active. Type `recieve` and Space again. The text stays `recieve `.

**Acceptance Scenarios**:

1. KeySwitch corrected `recieve` to `receive`. If the user taps Shift two times, the text
   becomes `recieve `. The layout stays English.
2. The user reverted `recieve`. If the user types `recieve` and Space again, the text stays
   the same.

### User Story 3: Technical words stay as typed (Priority: P2)

The user types names, commands and abbreviations. KeySwitch changes only a word for which
the system is sure of the correction.

**Why this priority**: An incorrect change of a command or a name is worse than a typo.

**Independent Test**: Set the option to on. Type `kubectl`, `README`, `iPhone`, `h2o` and
`ok`, each with Space. The text stays the same.

**Acceptance Scenarios**:

1. The option is on. If the system has no sure correction for the typed word, the text
   stays the same.
2. The option is on. If the user types a word with a digit, the text stays the same.
3. The option is on. If the user types a word of fewer than 3 letters, the text stays the
   same.
4. The option is on. If the user types a word with a capital letter after the first letter,
   the text stays the same.
5. The option is on and the front app is in the exclusion list. If the user types a typo,
   the text stays the same.

### Edge cases

- The layout correction of feature 001 examines the word first. The typo correction examines
  only a word that stays in the current layout.
- After a typo correction, Backspace clears the word buffer. A later double Shift tap then
  changes only the layout.
- A correction that needs more than 2 edits is too far from the typed word. KeySwitch
  ignores it.
- A correction with a space in it makes two words from one. KeySwitch ignores it.

## Requirements

### Functional requirements

- **FR-001**: The settings MUST have a switch for typo correction. The default MUST be off.
- **FR-002**: With the switch on, the app MUST examine each word that the user completes
  with Space or Return. A word that the layout correction changed is out of scope.
- **FR-003**: The app MUST replace the word only when the system spelling checker gives one
  correction with confidence.
- **FR-003a**: The app MUST accept a correction only when it is a word of the frequency
  list. If the typed word is also in the list, the correction MUST be 2 times more frequent.
- **FR-003b**: The app MUST keep a technical term of the bundled list as typed.
- **FR-004**: The app MUST keep the punctuation around the word and the capital first letter.
- **FR-005**: The app MUST ignore a word with a digit and a word of fewer than 3 letters.
  The app MUST ignore a word with a capital letter after the first letter. The app MUST
  ignore an exception word.
- **FR-006**: The app MUST ignore a correction that needs more than 2 edits. The app MUST
  ignore a correction that has a space.
- **FR-007**: A double Shift tap after a typo correction MUST bring back the original word
  and keep the layout. The app MUST then add the word to the exceptions.
- **FR-008**: The per-app exclusion of feature 001 MUST also stop the typo correction.
- **FR-009**: The typed text MUST stay in memory only, as feature 001 requires.

### Key entities

- **Typo correction**: the original word and the corrected word, kept until the user types
  the subsequent word.
- **Exceptions**: the same list as in feature 001.

## Success criteria

### Measurable outcomes

- **SC-001**: The end-to-end test corrects a known typo in English and in Russian.
- **SC-002**: A list of 30 technical words, names and abbreviations stays as typed.
- **SC-003**: One of the 15,000 most frequent words of a language costs no call to the
  system spelling checker.
- **SC-004**: One gesture reverts a correction.

## Assumptions

- The system spelling checker has the English and the Russian dictionaries. They are part of
  macOS.
- The confident correction of the system is the same one that macOS applies in its own text
  fields. It is careful: in a test it left `kubectl` and `превет` as typed.
- One call to the checker takes from 10 to 70 milliseconds. The user does not see this delay
  at the end of a word.
