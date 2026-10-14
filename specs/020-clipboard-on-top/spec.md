# Feature Specification: Clipboard history at the top of the menu

**Feature Branch**: `020-clipboard-on-top`

**Created**: 2026-10-14

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "сделай что бclipboard был сверху", with a screenshot of the menu.

## User scenarios and tests

### User Story 1: The user finds the clipboard history first (Priority: P1)

The user opens the menu of KeySwitch to paste an earlier entry. Now the switches of the
layout come first, and the user must move the pointer past them to the history.

With this feature, the clipboard part is at the top of the menu: "Search the History…",
the pinned entries, the entries, "Earlier" and "Clear History". The switches come after it.
"Settings…" and "Quit KeySwitch" stay at the bottom.

**Why this priority**: The user opens the menu for the history more frequently than for the
switches.

**Independent Test**: Set the history to on. Open the menu. The first item is "Search the
History…". The switch "Enabled" comes after the clipboard part.

**Acceptance Scenarios**:

1. The history is on. The clipboard part is the first part of the menu, and a divider
   separates it from the switches.
2. The history is off. The menu starts with the switches, as before.
3. The app has no accessibility access. The item "Grant Accessibility Access…" stays the
   first item of the menu.

## Requirements

### Functional requirements

- **FR-001**: With the history on, the clipboard part MUST come before the switches.
- **FR-002**: The item for the accessibility access MUST stay at the top.

## Success criteria

### Measurable outcomes

- **SC-001**: The app builds, and the unit tests pass.
