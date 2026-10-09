# Feature Specification: Selected text

**Feature Branch**: `005-selection`

**Created**: 2026-10-09

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "1 2 4 7 - do it." Item 1 of the proposal: convert the selected
text to the other layout. Item 4 also applies to the selected text.

## User scenarios and tests

### User Story 1: Double Shift converts the selected text (Priority: P1)

The user selects text that is in the incorrect layout: a word, a line or some lines. The
user taps Shift two times. KeySwitch replaces the selected text with the same keys in the
other layout.

**Why this priority**: The gestures of features 001 and 004 change only the text that the
user typed last. Old text needs a selection.

**Independent Test**: Select `ghbdtn vbh` in a text field. Tap Shift two times. The field
shows `привет мир`. Tap Shift two times again. The field shows `ghbdtn vbh`.

**Acceptance Scenarios**:

1. The user selected the text `ghbdtn vbh`. If the user taps Shift two times, the text becomes
   `привет мир` and Russian is active.
2. The user selected the text `руддщ`. If the user taps Shift two times, the text becomes `hello`
   and English is active.
3. KeySwitch converted a selection and the user pressed no key. If the user taps Shift two
   times again, the original text comes back.
4. The user selected no text and typed nothing. If the user taps Shift two times, the
   text stays the same.
5. The clipboard holds some content. If KeySwitch converts a selection, the clipboard holds
   the same content after that.

### User Story 2: Double Option changes the case of the selected text (Priority: P2)

The user selects text and taps Option two times. The case of the selected text changes in
the same order as for the last word.

**Independent Test**: Select `hello world`. Tap Option two times: `Hello world`. Tap Option
two times again: `HELLO WORLD`.

**Acceptance Scenarios**:

1. The user selected the text `hello world`. If the user taps Option two times, the text becomes
   `Hello world`.
2. KeySwitch changed the case of a selection and the user pressed no key. If the user taps
   Option two times again, the text becomes `HELLO WORLD`.

### Edge cases

- The user typed a word after the last caret movement: the gestures change that word, as in
  features 001 and 004. The selection gestures apply when the phrase buffer is empty.
- Some apps do not tell which text is selected. KeySwitch then copies the selection through
  the clipboard and restores the clipboard after that.
- Some editors copy the full line when no text is selected. KeySwitch ignores a copied text
  that is one line with a line end.
- A selection of more than 5000 characters stays the same.
- The option is off: the gestures change only the typed text.

## Requirements

### Functional requirements

- **FR-001**: With an empty phrase buffer, a double Shift tap MUST convert the selected text
  to the other layout.
- **FR-002**: The app MUST find the direction from the letters of the text. The layout of
  the result MUST become active.
- **FR-003**: With an empty phrase buffer, a double Option tap MUST change the case of the
  selected text.
- **FR-004**: The app MUST restore the content of the clipboard after each operation.
- **FR-005**: Until the user presses a key or a mouse button, the same gesture MUST work on
  the text that the app inserted.
- **FR-006**: The app MUST do nothing when no text is selected.
- **FR-007**: The settings MUST have a switch for the selection gestures. The default MUST
  be on.
- **FR-008**: The selected text MUST stay in memory only for the time of the operation.

## Success criteria

### Measurable outcomes

- **SC-001**: The end-to-end test converts a selection of two lines in the two directions.
- **SC-002**: The end-to-end test finds the clipboard content unchanged after a conversion.
- **SC-003**: All scenarios of features 001, 003 and 004 pass as before.

## Assumptions

- The app has the Accessibility permission. The same permission gives access to the selected
  text of an app.
- The Command-C and Command-V shortcuts copy and paste in the front app.
