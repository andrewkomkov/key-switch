# Feature Specification: New icon

**Feature Branch**: `018-app-icon`

**Created**: 2026-10-13

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "Мб иконочку переделай? А то в трее стрелка - а она вроде уже не отражает всю аппку".

## User scenarios and tests

### User Story 1: The icon shows the function of the app (Priority: P1)

The menu bar shows a Shift arrow. The arrow was correct for the first version, which had
only the Shift gesture. The app now corrects layouts, typos and capitals, and it keeps a
clipboard history. The arrow tells the user nothing about these functions.

The new icon is a key with the letters `A` and `я`: one Latin letter and one Cyrillic
letter. It tells the user that the app works with text in two languages. The app icon in
Finder shows the same two letters.

**Why this priority**: The icon is the only part of the app that the user always sees.

**Independent Test**: Start the app. The menu bar shows a filled key with the letters `Aя`.
Set "Enabled" to off. The key becomes an outline.

**Acceptance Scenarios**:

1. The app is on and has the Accessibility permission. The menu bar shows the filled key.
2. The app is off, or it has no permission. The menu bar shows the outline of the key.
3. The icon follows the colour of the menu bar: light on a dark bar, dark on a light bar.
4. Finder and the settings of macOS show the app icon with the letters `Aя`.

## Requirements

### Functional requirements

- **FR-001**: The menu bar icon MUST be a template image, so that macOS sets its colour.
- **FR-002**: The menu bar icon MUST have two states: filled for an active app, outline for
  an app that does nothing.
- **FR-003**: The app icon MUST show the same letters as the menu bar icon.
- **FR-004**: VoiceOver MUST read the name of the app for the menu bar icon.

## Success criteria

### Measurable outcomes

- **SC-001**: The app builds, and the unit tests pass.
- **SC-002**: All scenarios of the end-to-end test pass as before.
- **SC-003**: The two letters are legible at the size of the menu bar.

## Assumptions

- The colours of the app icon stay. Only the symbol changes.
- The icon does not show the current layout. The user did not want a layout indicator.
