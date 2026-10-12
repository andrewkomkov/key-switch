# Feature Specification: The letter ё

**Feature Branch**: `008-yofication`

**Created**: 2026-10-12

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "a yoficator: put the letter ё where it must be in place of е".

## User scenarios and tests

### User Story 1: A completed word gets its ё (Priority: P1)

The user types Russian text and uses the `е` key for the two letters. When the user
completes a word with Space or Return, the app puts `ё` in the word if the word always has
it.

**Why this priority**: The `ё` key is far from the other letters, and most people do not
use it.

**Independent Test**: Set the option to on. In Russian, type `еще` and Space. The field
shows `ещё `.

**Acceptance Scenarios**:

1. The user typed `еще` in Russian. If the user presses Space, the text becomes `ещё `.
2. The user typed `все` in Russian. If the user presses Space, the text stays `все `,
   because `все` and `всё` are two different words.
3. The user typed `ЕЩЕ`. If the user presses Space, the text becomes `ЕЩЁ `.
4. The app changed `еще` to `ещё`. If the user taps Shift two times, the text becomes `еще `
   again. The layout stays Russian, and `еще` goes to the exceptions.
5. The word `еще` is an exception. If the user types it, the text stays as typed.
6. The option is off. If the user types `еще` and Space, the text stays `еще `.

### User Story 2: A converted word gets its ё (Priority: P2)

The user types a Russian word in the English layout. The app converts the word, and the
result has `ё` where the word needs it.

**Why this priority**: Without this, the text of one user has the two spellings.

**Independent Test**: Set the option to on. In English, type `ptktysq` and Space. The field
shows `зелёный `.

**Acceptance Scenarios**:

1. The user typed `ptktysq` in English. If the user presses Space, the text becomes
   `зелёный ` and Russian is active.
2. The app converted the word. If the user taps Shift two times, the text becomes `ptktysq `.
3. Automatic correction is off. If the user types `ptktysq` and taps Shift two times, the
   text becomes `зелёный`.

### Edge cases

- A name gets `ё` only with a capital first letter: `Артем` becomes `Артём`, and `артем`
  stays.
- A word with capitals in the middle stays as typed.
- A word in an excluded app stays as typed.
- A word that the typo correction changed gets no second change.
- The selection gestures of feature 005 do not add `ё`.

## Requirements

### Functional requirements

- **FR-001**: The app MUST put `ё` only into the words of a list where `е` in that place is
  always `ё`.
- **FR-002**: The change MUST keep the case of each letter and the length of the word.
- **FR-003**: A double Shift tap after the change MUST bring the typed word back and MUST add
  the word to the exceptions.
- **FR-004**: The app MUST apply the same list to the result of an automatic conversion and
  of a manual conversion of typed words.
- **FR-005**: The settings MUST have a switch for this function. The default MUST be off.
- **FR-006**: The typed text MUST stay in memory only, as feature 001 requires.

## Success criteria

### Measurable outcomes

- **SC-001**: The list restores `ё` in `еще`, `ее`, `елка`, `идет` and `черный`.
- **SC-002**: The list changes none of these words: `все`, `нем`, `небо`, `осел`, `берет`.
- **SC-003**: The end-to-end test passes with the scenarios of this feature.
- **SC-004**: All scenarios of features 001 to 007 pass as before.

## Assumptions

- The "safe" dictionary of the eyo-kernel project has no word with two correct spellings.
- A word outside the list stays as typed. The app does not guess.
