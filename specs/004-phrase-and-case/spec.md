# Feature Specification: Phrase conversion and case change

**Feature Branch**: `004-phrase-and-case`

**Created**: 2026-10-09

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "1 2 4 7 - do it." Items 2 and 4 of the proposal: a repeated
double Shift takes one more word to the left, and a hotkey changes the case of the last word.

## User scenarios and tests

### User Story 1: More Shift taps convert more words (Priority: P1)

The user typed some words in the incorrect layout and sees it late. The user taps Shift two
times: the last word changes. Each subsequent tap of the same series changes one more word
to the left.

**Why this priority**: The double Shift tap corrects one word only. A phrase needs one
gesture for each word, and the caret must go back to each word.

**Independent Test**: Set automatic correction to off. In English, type `ghbdtn vbh` and
Space. Tap Shift three times quickly. The field shows `привет мир `.

**Acceptance Scenarios**:

1. The user typed `ghbdtn vbh ` in English. If the user taps Shift three times in one
   series, the text becomes `привет мир ` and Russian is active.
2. The user converted two words with three taps. If the user later taps Shift two times, the
   two words come back as typed.
3. The user typed one word. If the user taps Shift four times in one series, only that word
   changes.
4. The user typed a new word after a conversion. If the user taps Shift two times, only the
   new word changes.

### User Story 2: Double Option changes the case (Priority: P2)

The user typed a word with the incorrect case. The user taps Option two times. The case of
the last word changes. Each subsequent tap of the same series gives the subsequent case.

**Why this priority**: A word typed with Caps Lock on needs a full retype today.

**Independent Test**: Type `hello`. Tap Option two times: `Hello`. Tap one more time in the
same series: `HELLO`. Type `hELLO` and tap Option two times: `Hello`.

**Acceptance Scenarios**:

1. The last word is `hello`. If the user taps Option two times, the word becomes `Hello`.
2. The last word is `Hello`. If the user taps Option two times, the word becomes `HELLO`.
3. The last word is `HELLO`. If the user taps Option two times, the word becomes `hello`.
4. The last word is `hELLO`. If the user taps Option two times, the word becomes `Hello`.
5. The user holds Option and types a character. The text gets that character only.
6. The case option is off. If the user taps Option two times, the text stays the same.

### Edge cases

- A series stops when the user presses a key or a mouse button, or waits longer than the
  interval between taps.
- The buffer keeps 256 keys of the phrase. Older words are out of reach.
- A typo correction of feature 003 stops the phrase at that word.
- After a case change, a double Shift tap converts the word with its new case.

## Requirements

### Functional requirements

- **FR-001**: The app MUST keep the keys of the phrase from the last caret movement, with a
  limit of 256 keys.
- **FR-002**: The third and each later Shift tap of one series MUST add one word to the left
  to the converted text.
- **FR-003**: A later double Shift tap MUST convert the same words back.
- **FR-004**: A double Option tap MUST change the case of the last word in this order:
  small letters, first capital, all capitals.
- **FR-005**: For a word that starts with a small letter and continues in capitals, the app
  MUST invert the case of each letter.
- **FR-006**: The settings MUST have a switch for the case gesture. The default MUST be on.
- **FR-007**: The typed text MUST stay in memory only, as feature 001 requires.

## Success criteria

### Measurable outcomes

- **SC-001**: One series of taps converts a phrase of three words. The caret stays in place.
- **SC-002**: The end-to-end test passes with the phrase scenarios and the case scenarios.
- **SC-003**: All scenarios of features 001 and 003 pass as before.

## Assumptions

- macOS gives no function to a double tap of the Option key.
- A phrase is the text that the user typed after the last caret movement.
