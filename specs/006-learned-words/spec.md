# Feature Specification: Learned words

**Feature Branch**: `006-learned-words`

**Created**: 2026-10-09

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "1 2 4 7 - do it." Item 7 of the proposal: learn from the user.
Add to the dictionary the words that the user types often and does not revert.

## User scenarios and tests

### User Story 1: A word that the user types often becomes known (Priority: P1)

The user sets learning to on. The user types a word that the dictionary does not have, for
example `гит`, three times in one session. KeySwitch learns the word. From then on, the
automatic correction knows the word: it converts `ubn` to `гит`, and the typo correction
keeps `гит` as typed.

**Why this priority**: The dictionary comes from film subtitles. It does not have the work
words of the user, and the detector ignores short unknown words.

**Independent Test**: Set learning to on. In Russian, type `гит` and Space three times. In
English, type `ubn` and Space. The field shows `гит `.

**Acceptance Scenarios**:

1. Learning is on. If the user types `гит` and Space three times in Russian, the list of
   learned words gets `гит`.
2. The list has `гит`. If the user types `ubn` and Space in English, the text becomes
   `гит ` and Russian is active.
3. Learning is off. If the user types `гит` three times, the list stays empty.
4. The user removed `гит` from the list. If the user types `ubn` and Space, the text stays
   the same.

### User Story 2: A manual conversion teaches the word immediately (Priority: P1)

The detector did not convert a word. The user converts it with a double Shift tap. KeySwitch
learns the result immediately and converts the word by itself from then on.

**Why this priority**: A manual conversion is the clearest signal from the user.

**Independent Test**: Set learning to on. In English, type `fghed` and tap Shift two times:
`апрув`. Clear the field. In English, type `fghed` and Space. The field shows `апрув `.

**Acceptance Scenarios**:

1. Learning is on. If the user converts `fghed` to `апрув` with a double Shift tap, the list
   gets `апрув`.
2. The list has `апрув`. If the user types `fghed` and Space in English, the text becomes
   `апрув `.

### Edge cases

- KeySwitch learns only a word of 3 to 24 letters of its language. A word with a digit or
  with punctuation in it stays out.
- A string of random letters stays out: the letter model must find the word possible.
- The counts of words that are not learned yet stay in memory and go away when the app stops.
- A manual conversion removes the original reading from the counts and from the list.
- The per-app exclusion also stops the learning in that app.
- macOS hides the keys of password fields. A password in a usual text field can get into
  the list after three entries, if it has letters only. This is why learning is off by default.

## Requirements

### Functional requirements

- **FR-001**: The settings MUST have a switch for learning. The default MUST be off.
- **FR-002**: With learning on, the app MUST count each completed word that stays as typed
  and that the dictionary does not have.
- **FR-003**: The app MUST add a word to the learned words after 3 counts in one session.
- **FR-004**: The app MUST add the result of a manual conversion to the learned words
  immediately, if the dictionary does not have it.
- **FR-005**: The detector and the typo correction MUST use a learned word as a frequent
  dictionary word.
- **FR-006**: The settings MUST show the learned words and let the user remove each one.
- **FR-007**: The app MUST store only the learned words. The counts and all other typed text
  MUST stay in memory.

## Success criteria

### Measurable outcomes

- **SC-001**: After 3 entries of an unknown word, the end-to-end test gets an automatic
  conversion of that word from the other layout.
- **SC-002**: With learning off, the list of learned words stays empty in the end-to-end test.
- **SC-003**: All scenarios of features 001 to 005 pass as before.

## Assumptions

- This feature needs an amendment of principle I of the constitution. With the amendment,
  the app can store single words that the user typed, but only with learning on.
- A word is learnable only if its reading in the other layout is not a word. For a counted
  word, one of the two readings must also be clear for the letter model.
