# Feature Specification: Correction of accidental capitals

**Feature Branch**: `010-capital-fix`

**Created**: 2026-10-12

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "Correction of an accidental Caps Lock and of two capitals:
`пРИВЕТ` becomes `Привет`, `ПРивет` becomes `Привет` at the space. The same double Shift
reverts it." The user said: "2 - давай".

## User scenarios and tests

### User Story 1: Two capitals at the start of a word (Priority: P1)

The user holds Shift for too long and types `ПРивет`. The user presses Space. The word
becomes `Привет`.

**Why this priority**: This is the most frequent case error in fast typing.

**Independent Test**: Type `HEllo` and press Space. The text is `Hello `.

**Acceptance Scenarios**:

1. The option is on. If the user types `HEllo` and presses Space, the text becomes `Hello `.
2. If the user then taps Shift two times, the text becomes `HEllo ` again, and the word
   becomes an exception.
3. If the user types an exception word with two capitals, the word stays as typed.
4. If the user types `IDs`, `OSes` or `МВт`, the word stays as typed.
5. The option is off. If the user types `HEllo` and presses Space, the text stays `HEllo `.
6. If the user types `GHbdtn` in the English layout, the text becomes `Привет `.

### User Story 2: A word with inverted case (Priority: P2)

The user types `hELLO`: a small first letter, then capitals. The user presses Space. The
word becomes `Hello`.

**Why this priority**: On a Mac, Caps Lock with Shift gives a capital, so this text is rare.
It comes from a remote session or from a keyboard with a different Caps Lock function.

**Acceptance Scenarios**:

1. If the user types `hELLO` and presses Space, the text becomes `Hello `.
2. If the user types `iOS`, the word stays as typed.

### Edge cases

- A word in capitals only, such as `HELLO`, stays as typed. The user can want it.
- A word that the dictionary does not have stays as typed.
- A word of 3 letters with `s` at the end, such as `TVs`, stays as typed.
- Punctuation before and after the word stays in its position.
- The word is in an excluded app. The app does nothing there.

## Requirements

### Functional requirements

- **FR-001**: The first pattern is two capitals at the start and small letters after them.
  With the option on, the app MUST give a completed word of this pattern one capital.
- **FR-002**: The second pattern is a small first letter and capitals after it, in a word of
  4 or more letters. The app MUST give a completed word of this pattern one capital.
- **FR-003**: The app MUST change only a word that the dictionary or the learned list has.
- **FR-004**: A double Shift tap MUST bring the typed word back and make it an exception.
- **FR-005**: The app MUST apply the same rule to a word that it converts from the other
  layout.
- **FR-006**: The settings MUST have a switch for the option. The default MUST be on.

## Success criteria

### Measurable outcomes

- **SC-001**: The unit tests pass for the two patterns and for the words that must stay.
- **SC-002**: The end-to-end test passes with the scenarios of this feature.
- **SC-003**: All scenarios of features 001 to 009 pass as before.

## Assumptions

- The app does not change the Caps Lock state. On a Mac the Caps Lock key does not make the
  inverted pattern.
- The default is on, because two capitals at the start of a dictionary word are an error.
