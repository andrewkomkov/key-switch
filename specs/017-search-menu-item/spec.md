# Feature Specification: Menu item for the clipboard search

**Feature Branch**: `017-search-menu-item`

**Created**: 2026-10-12

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "поиск как вызвать? Чето не вижу его в меню", then "давай, добавь в меню".

## User scenarios and tests

### User Story 1: The user opens the search from the menu (Priority: P1)

The user knows that the app has a search in the clipboard history. The user opens the menu
of KeySwitch and finds no search there. The shortcut is only in the settings window.

With this feature, the clipboard part of the menu starts with the item "Search the
History…". The item shows the shortcut. A click on the item opens the same panel as the
shortcut.

**Why this priority**: The user must find each function in the menu.

**Independent Test**: Put the caret in a text field. Open the menu of KeySwitch.
Click "Search the History…". The search panel opens. Select an entry. Press Return. The
text field gets the entry.

**Acceptance Scenarios**:

1. The history is on. The menu shows the item "Search the History…" above the entries.
2. If the user clicks the item, the search panel opens, and the front app stays the front app.
3. The search option is on. The item shows the shortcut Control-Option-V.
4. The search option is off. The item shows no shortcut, and a click opens the panel.
5. The history is off. The menu does not show the item.

## Requirements

### Functional requirements

- **FR-001**: With the history on, the menu MUST show an item that opens the search panel.
- **FR-002**: The item MUST show the shortcut only while the shortcut is on.
- **FR-003**: The item MUST have a Russian text.

## Success criteria

### Measurable outcomes

- **SC-001**: The app builds, and the unit tests pass.
- **SC-002**: All scenarios of the end-to-end test pass as before.

## Assumptions

- The search option in the settings is a switch for the shortcut only. The menu item
  works with the option off.
