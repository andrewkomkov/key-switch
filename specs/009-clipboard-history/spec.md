# Feature Specification: Clipboard history

**Feature Branch**: `009-clipboard-history`

**Created**: 2026-10-12

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "let us extend the function and add copyclip too". The user
then selected: the menu only, as in CopyClip; storage on the disk; text and images.

## User scenarios and tests

### User Story 1: The menu shows what the user copied (Priority: P1)

The user copies some pieces of text, one after the other. Later the user needs an earlier
piece. The user opens the KeySwitch menu in the menu bar and clicks the piece. The piece is
in the clipboard again, and Command-V pastes it.

**Why this priority**: The clipboard of macOS holds one item. A second copy deletes the first.

**Independent Test**: Set the option to on. Copy `alpha`, then `beta`. Open the menu. Click
`alpha`. Press Command-V. The app gets `alpha`.

**Acceptance Scenarios**:

1. The option is on. If the user copies `alpha` and then `beta`, the menu shows `beta` first
   and `alpha` second.
2. The history has `beta` and `alpha`. If the user copies `alpha` again, the menu shows
   `alpha` first and `beta` second, with no second `alpha`.
3. If the user clicks an entry, the clipboard gets that entry, and the entry goes to the top.
4. The history is at its limit. If the user copies a new item, the oldest entry goes away.
5. The option is off. If the user copies text, the history stays the same.
6. If the user selects "Clear History", the history and its files go away.

### User Story 2: The history keeps images (Priority: P2)

The user copies an image or takes a screenshot to the clipboard. The menu shows a small
picture of it. A click puts the image in the clipboard again.

**Why this priority**: A screenshot in the clipboard is easy to lose with the next copy.

**Independent Test**: Copy an image. Copy text. Click the image entry in the menu. Paste
into an app that accepts images.

**Acceptance Scenarios**:

1. If the user copies an image with no text, the history gets an image entry.
2. If the user clicks an image entry, the clipboard gets the image.
3. If an image entry leaves the history, its file leaves the disk.

### User Story 3: The history stays after a restart (Priority: P2)

The user restarts the Mac. The menu shows the same entries as before.

**Acceptance Scenarios**:

1. The history has entries. If the app starts again, the menu shows the same entries in the
   same order.

### Edge cases

- A password manager marks its copy as concealed. The history ignores a concealed item, a
  transient item and an automatically generated item, as nspasteboard.org defines them.
- The history ignores the clipboard changes that KeySwitch makes for a selection gesture and
  for a plain paste.
- The history ignores copied files.
- An item with text and an image becomes a text entry. The format of the text is not kept.
- The history ignores text longer than 200,000 characters and an image larger than 20 MB.
- An app that does not mark a password as concealed puts it in the history. The settings
  tell the user this.
- macOS can ask the user to permit KeySwitch to read the clipboard.

## Requirements

### Functional requirements

- **FR-001**: With the option on, the app MUST add each new text or image of the clipboard
  to the history.
- **FR-002**: The history MUST hold each content one time, with the newest first.
- **FR-003**: The history MUST have a limit that the user sets: 10, 25, 50 or 100 entries.
  The default MUST be 25.
- **FR-004**: The menu of the app MUST show the entries. A click MUST put the entry in the
  clipboard.
- **FR-005**: The app MUST keep the history in a folder that only the user can read.
- **FR-006**: The app MUST ignore concealed, transient and automatically generated items, and
  its own clipboard changes.
- **FR-007**: The settings MUST have a switch for the history. The default MUST be off.
- **FR-008**: The settings MUST show the entries, and the user MUST be able to remove one
  entry or all of them.
- **FR-009**: The content of the clipboard MUST stay out of the log and out of the network.

### Key entities

- **Entry**: one copied item. It has an identifier, a time, and text or the name of an
  image file with the size of the image.
- **History**: an ordered list of entries with a limit.

## Success criteria

### Measurable outcomes

- **SC-001**: An entry is in the menu not later than 1 second after the copy.
- **SC-002**: The end-to-end test passes with the scenarios of this feature.
- **SC-003**: All scenarios of features 001 to 008 pass as before.

## Assumptions

- The clipboard of macOS gives no notification. The app reads the change count 2 times each
  second.
- The user accepts that copied content is on the disk of this Mac while the option is on.
