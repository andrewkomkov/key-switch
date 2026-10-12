# Feature Specification: Paste without formatting

**Feature Branch**: `007-plain-paste`

**Created**: 2026-10-12

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "more features: on cmd+shift+v, paste without formatting".

## User scenarios and tests

### User Story 1: Command-Shift-V pastes plain text (Priority: P1)

The user copied text from a web page. The text has a font, a size and a colour. The user
presses Command-Shift-V in a different app. The app gets the text only, in the format of the
text around the caret.

**Why this priority**: Each app has a different shortcut for this function, and some apps
have none.

**Independent Test**: Copy bold text of 40 points. Press Command-Shift-V in a rich text
field. The field shows the text in its own font.

**Acceptance Scenarios**:

1. The text in the clipboard has a format. If the user presses Command-Shift-V, the app gets the
   text without the format.
2. The user pasted plain text. The clipboard has its original content again. If the user
   then presses Command-V, the app gets the text with its format.
3. The clipboard has an image and no text. If the user presses Command-Shift-V, the front
   app gets the shortcut as usual.
4. The option is off. If the user presses Command-Shift-V, the front app gets the shortcut
   as usual.
5. The front app is in the list of excluded apps. If the user presses Command-Shift-V, the
   front app gets the shortcut as usual.

### Edge cases

- The shortcut is the V key with Command and Shift only. With Option or Control, the front
  app gets the shortcut.
- While the user holds the keys, the key repeats. Each repeat pastes the text one more time.
  A repeat that comes before the end of the previous paste does nothing.
- Some apps use Command-Shift-V for a different function. KeySwitch takes the shortcut from
  them. The list of excluded apps gives the shortcut back to an app.

## Requirements

### Functional requirements

- **FR-001**: On Command-Shift-V, the app MUST paste the text of the clipboard without its
  format.
- **FR-002**: After the paste, the clipboard MUST have its original content.
- **FR-003**: The app MUST leave the shortcut to the front app if the clipboard has no text.
- **FR-004**: The settings MUST have a switch for this shortcut. The default MUST be on.
- **FR-005**: The app MUST leave the shortcut to an excluded app.
- **FR-006**: The text of the clipboard MUST stay out of the disk and out of the log.

## Success criteria

### Measurable outcomes

- **SC-001**: One shortcut pastes plain text in each app that accepts Command-V.
- **SC-002**: The end-to-end test passes with the paste scenarios.
- **SC-003**: All scenarios of features 001 to 006 pass as before.

## Assumptions

- An app that gets only plain text from the clipboard pastes it in the format of the text
  around the caret.
- A clipboard manager ignores an entry that has the transient mark of nspasteboard.org.
