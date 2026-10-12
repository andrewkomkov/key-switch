# Feature Specification: Pinned clipboard entries

**Feature Branch**: `011-pinned-clipboard`

**Created**: 2026-10-12

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "Pinned entries in the clipboard history. The limit does not
push them out, so they are a set of permanent templates." The user said: "7 - давай".

## User scenarios and tests

### User Story 1: A pinned entry stays (Priority: P1)

The user copies an address that they paste each day. The user pins the entry. The user then
copies 100 other items. The address is still in the menu, in its own group at the top.

**Why this priority**: The history drops the oldest entry at the limit. A text that the user
needs each day goes away with the others.

**Independent Test**: Set the limit to 10. Copy `alpha` and pin it. Copy 10 other texts.
Open the menu. `alpha` is in the "Pinned" group.

**Acceptance Scenarios**:

1. If the user pins an entry, the menu shows it in the "Pinned" group, before the others.
2. The history is at its limit and has a pinned entry. If the user copies a new item, the
   oldest entry that is not pinned goes away.
3. If the user selects "Clear History", the pinned entries stay.
4. If the user copies the content of a pinned entry again, the entry keeps its pin. The
   history gets no second entry.
5. If the user removes the pin, the entry goes back to the other entries.
6. Some entries have a pin. If the app starts again, the same entries have a pin.

### User Story 2: The user pins from the menu and from the settings (Priority: P2)

The user holds Option and clicks an entry in the menu. The entry becomes pinned. A second
Option-click removes the pin. Each row of the "Clipboard" tab has a pin button too.

**Acceptance Scenarios**:

1. If the user holds Option and clicks an entry, the pin changes, and the clipboard stays
   the same.
2. If the user clicks the pin button of a row in the settings, the pin changes.
3. If the user clicks the remove button of a pinned row, the entry goes away.

### Edge cases

- The pinned entries do not count for the limit.
- A history file from version 0.5.0 has no pin data. All its entries are not pinned.
- The user removes a pin, and the history has more entries than the limit. The oldest entry
  that is not pinned goes away.
- An image entry can have a pin. Its file stays on the disk.

## Requirements

### Functional requirements

- **FR-001**: Each entry MUST have a pin state that the user can change.
- **FR-002**: The limit and "Clear History" MUST apply only to the entries without a pin.
- **FR-003**: The menu MUST show the pinned entries in their own group, before the others.
- **FR-004**: An Option-click on an entry in the menu MUST change its pin.
- **FR-005**: The "Clipboard" tab MUST have a pin button for each entry.
- **FR-006**: The pin state MUST stay after a restart.
- **FR-007**: The app MUST read a history file that has no pin data.

## Success criteria

### Measurable outcomes

- **SC-001**: The unit tests pass for the limit, the clear function and the old file format.
- **SC-002**: The end-to-end test passes with the scenarios of this feature.
- **SC-003**: All scenarios of features 001 to 010 pass as before.

## Assumptions

- The number of pinned entries has no limit. The user removes those that they do not need.
- A pinned entry is on the disk in the same folder and with the same file modes as the
  other entries. The constitution permits this with the clipboard history on.
