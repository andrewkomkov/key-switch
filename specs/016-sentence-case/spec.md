# Feature Specification: Capital letter at the start of a sentence

**Feature Branch**: `016-sentence-case`

**Created**: 2026-10-12

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "Заглавная буква в начале предложения. - норм". The proposal
was: macOS does this only in its own apps, and KeySwitch can do it in all apps.

## User scenarios and tests

### User Story 1: The word after a full stop gets a capital (Priority: P1)

The user types `Привет. как дела` in a messenger that has no automatic capitals. When the
user completes the word `как`, it becomes `Как`.

**Why this priority**: macOS gives the capital only in apps that use its text system.

**Independent Test**: Set the option to on. Type `hello. hello` and Space in an Electron app.
The text is `hello. Hello `.

**Acceptance Scenarios**:

1. The option is on. The user types a word, a full stop, a space, a second word and a space.
   The second word gets a capital first letter.
2. The same applies after `!` and after `?`.
3. If the user then taps Shift two times, the typed word comes back and becomes an exception.
4. If the previous word is an abbreviation, such as `etc.` or `т.е.`, the word stays.
5. If the previous word has one letter and a full stop, such as an initial, the word stays.
6. If the previous word ends with `..`, the word stays.
7. If the word has a capital in it, a digit or a symbol, such as `iPhone` or `v2`, it stays.
8. The option is off. The text stays as typed.
9. The app converts the word from the other layout. The converted word gets the capital.

### Edge cases

- The app knows only the phrase that the user typed without a caret move. After a click, an
  arrow key or the Return key, the app does not know the previous word and changes nothing.
- The first word of a new line or of a new message stays as typed. In a terminal and in a
  code editor, a capital there is an error.
- The front app is in the list of excluded apps. The text stays as typed.

## Requirements

### Functional requirements

- **FR-001**: A sentence starts after a word with `.`, `!` or `?` at its end. With the
  option on, the app MUST give a capital first letter to a completed word at that position.
- **FR-002**: The app MUST keep the word as typed after an abbreviation, an initial and
  an ellipsis.
- **FR-003**: The app MUST change only a word of small letters.
- **FR-004**: A double Shift tap MUST bring the typed word back and make it an exception.
- **FR-005**: The settings MUST have a switch for the option. The default MUST be off.

## Success criteria

### Measurable outcomes

- **SC-001**: The unit tests pass for the rules.
- **SC-002**: The end-to-end test passes with the scenarios of this feature.
- **SC-003**: All scenarios of features 001 to 015 pass as before.

## Assumptions

- The default is off. The option changes words in each app, and a terminal command can have
  a full stop before a space.
- The capital after the Return key is out of scope. It needs a list of apps where a new
  line starts a sentence.
