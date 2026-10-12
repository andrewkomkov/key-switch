# Feature Specification: Search in the clipboard history

**Feature Branch**: `014-clipboard-search`

**Created**: 2026-10-12

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "Поиск по истории. - норм". The proposal was: a shortcut opens a
small window with a search field, and Enter pastes the found entry.

## User scenarios and tests

### User Story 1: The user finds an entry with the keyboard (Priority: P1)

The history has 100 entries. The user types in a chat app and needs an address that they
copied in the morning. The user presses Control-Option-V. A small panel opens with a search
field and the list of entries.

The user types some letters of the address. The list shows
the entries that have these letters. The user presses Return. The panel closes, and the
address is in the chat app.

**Why this priority**: A menu with 100 entries is slow to read. The hands stay on the keys.

**Independent Test**: Copy `alpha` and `beta`. Put the caret in a text field. Press
Control-Option-V, type `alp`, press Return. The field gets `alpha`.

**Acceptance Scenarios**:

1. The history is on. If the user presses Control-Option-V, the panel opens, and the front
   app stays the front app.
2. If the user types text, the list shows only the entries that have each typed word. The
   letter case has no effect.
3. If the user presses Return, the selected entry goes to the clipboard and to the front app.
4. If the user presses the Down or Up arrow, the selection moves in the list.
5. If the user presses Escape or clicks out of the panel, the panel closes with no change.
6. With an empty search field, the list shows the pinned entries first, then the others.
7. The history or the search option is off. Control-Option-V goes to the front app.

### Edge cases

- While the panel is open, the app stops the layout conversion and each other automatic
  change. The search text stays as typed.
- An image entry has no text. It shows only with an empty search field.
- The search finds zero entries. The list is empty, and Return does nothing.
- The selected entry goes to the top of the history, the same as after a click in the menu.

## Requirements

### Functional requirements

- **FR-001**: With the history and the search option on, Control-Option-V MUST open the
  search panel and MUST NOT reach the front app.
- **FR-002**: The panel MUST get the keys and MUST NOT make KeySwitch the active app.
- **FR-003**: The list MUST show the entries that have each word of the search text, with no
  regard to letter case.
- **FR-004**: Return MUST put the selected entry in the clipboard and paste it in the front
  app.
- **FR-005**: Escape MUST close the panel with no change to the clipboard.
- **FR-006**: The settings MUST have a switch for the shortcut. The default MUST be on.

## Success criteria

### Measurable outcomes

- **SC-001**: The unit tests pass for the search rules.
- **SC-002**: The end-to-end test opens the panel with the shortcut, finds an entry and gets
  its text in the test window.
- **SC-003**: All scenarios of features 001 to 013 pass as before.

## Assumptions

- Control-Option-V is free in most apps. The user can set the option to off if an app
  needs it.
- The menu stays as it is. The panel is a second way to the same history.
