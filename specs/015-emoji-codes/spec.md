# Feature Specification: Emoji codes

**Feature Branch**: `015-emoji-codes`

**Created**: 2026-10-12

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "Эмодзи по коду. :fire: + пробел → 🔥 в любой программе, откат <!-- slop: the words of the user -->
двойным Shift. - норм"

## User scenarios and tests

### User Story 1: A code becomes an emoji (Priority: P1)

The user knows the emoji codes of GitHub and Slack. The user types `:fire:` and Space in an
app that has no such function. The text gets the emoji.

**Why this priority**: The emoji panel of macOS needs the mouse or a search. A code is faster.

**Independent Test**: Type `:fire:` and Space in TextEdit. The text is the fire emoji and a
space.

**Acceptance Scenarios**:

1. The option is on. If the user types a known code and presses Space or Return, the emoji
   replaces the code.
2. If the user then taps Shift two times, the code comes back and becomes an exception.
3. If the user types an unknown code, such as `:nosuchcode:`, the text stays as typed.
4. If the user types a word with only one colon, such as `fire:`, the text stays as typed.
5. The option is off. If the user types a known code, the text stays as typed.
6. The Russian layout is active, and the keys of the user give `:fire:` in the English
   layout. The emoji replaces the typed text.

### Edge cases

- The code must be the full word: a colon, the name, a colon. Text such as `10:30:` or
  `a:fire:` stays.
- The front app is in the list of excluded apps. The text stays as typed.
- A text replacement of macOS with the same shortcut wins.

## Requirements

### Functional requirements

- **FR-001**: With the option on, the app MUST replace a completed word of the form
  `:name:` with the emoji of that name.
- **FR-002**: The list of names MUST be in the app. The app MUST NOT use the network.
- **FR-003**: A double Shift tap MUST bring the code back and make it an exception.
- **FR-004**: The app MUST find a code that the user typed with the keys of the English
  layout while a different layout was active.
- **FR-005**: The settings MUST have a switch for the option. The default MUST be on.

## Success criteria

### Measurable outcomes

- **SC-001**: The unit tests pass for the format rules and for the full list.
- **SC-002**: The end-to-end test passes with the scenarios of this feature.
- **SC-003**: All scenarios of features 001 to 014 pass as before.

## Assumptions

- The list is the gemoji list of GitHub: 1,913 codes, MIT license.
- The default is on, because the form `:name:` is rare in usual text.
