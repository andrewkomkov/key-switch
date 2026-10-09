# Feature Specification: Layout switcher

**Feature Branch**: `001-layout-switcher`

**Created**: 2026-10-09

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "A program like Punto Switcher and Caramba Switcher. Main
features: change the language with Shift, and with a double press rewrite what was typed in
the other layout. Also find an effective way to do automatic switching. Native macOS 27 app."

## User scenarios and tests

### User Story 1: Shift tap changes the layout (Priority: P1)

The user presses and releases Shift and presses no other key. The next enabled keyboard
layout becomes active.

**Why this priority**: The user asked for this gesture first. Story 2 uses it.

**Independent Test**: Enable two layouts. Tap Shift. The input menu shows the other layout.
Type `Shift+A`. The layout stays the same.

**Acceptance Scenarios**:

1. English is active. If the user taps the left or the right Shift, Russian becomes active.
2. Shift is down. If the user presses a letter, a mouse button or a second modifier, the
   layout stays the same.
3. Shift is down for longer than the tap timeout. If the user releases it, the layout stays
   the same.

### User Story 2: Double Shift tap types the last word again (Priority: P1)

The user typed a word in the incorrect layout. The user taps Shift two times quickly.
KeySwitch replaces the word with the same keys in the other layout. That layout stays active.

**Why this priority**: This is the second feature that the user named.

**Independent Test**: In the English layout, type `ghbdtn`. Tap Shift two times. The field
shows `привет` and Russian is active. Tap Shift two times again. The field shows `ghbdtn`.

**Acceptance Scenarios**:

1. The user typed `ghbdtn` in English. If the user taps Shift two times, the text becomes
   `привет` and Russian is active.
2. A word has spaces after it. If the user taps Shift two times, KeySwitch converts the word
   and keeps the spaces.
3. The caret moved after the last key. If the user taps Shift two times, only the layout
   changes.
4. KeySwitch converted a word. If the user taps Shift two times again, the original text
   comes back.

### User Story 3: Automatic correction (Priority: P2)

The user types in the incorrect layout. The user completes the word with Space or Return.
KeySwitch finds that the word has no sense in the current language and is a word in the other
language. KeySwitch replaces the word and changes the layout.

**Why this priority**: The user asked for research and a solution. This story must not
damage stories 1 and 2.

**Independent Test**: In the English layout, type `ghbdtn` and Space. The field shows
`привет ` and Russian is active. Type `kubectl` and Space in English. The text stays the same.

**Acceptance Scenarios**:

1. English is active. If the user types `ghbdtn` and Space, the text becomes `привет ` and
   Russian is active.
2. Russian is active. If the user types `руддщ` and Space, the text becomes `hello ` and
   English is active.
3. English is active. If the user types an English word or a technical term such as
   `kubectl`, the text stays the same.
4. KeySwitch made an automatic correction. If the user taps Shift two times, the original
   text comes back and the word becomes an exception.
5. Automatic correction is off for all apps or for the front app. If the user types,
   KeySwitch makes no automatic correction.

### User Story 4: Menu bar app with settings (Priority: P3)

The app stays in the menu bar. The menu has four controls: a pause switch, a switch for
automatic correction, an exclusion for the front app, and a link to the settings.
The app helps the user to give the Accessibility permission.

**Independent Test**: Start the app without the permission. A window tells the user which
permission to give. The app starts to work when the permission is there.

**Acceptance Scenarios**:

1. The Accessibility permission is absent. If the app starts, a window opens with a button
   for the correct pane of System Settings.
2. That window is open. If the user gives the permission, the app starts to work without a
   restart.
3. The app is active. If the user opens the menu bar item, the controls of this story are
   there.

### Edge cases

- Password fields: macOS hides the keys of a secure field from the app. The app records
  nothing there.
- A key with Command, Control or Option clears the word buffer.
- A word with a digit and a word of one letter get no automatic correction.
- More than two layouts: Shift goes through all of them. The automatic correction uses the
  first layout of the other language.
- Fewer than two layouts: the app does nothing.

## Requirements

### Functional requirements

- **FR-001**: A Shift tap shorter than the tap timeout MUST select the next enabled layout.
- **FR-002**: Shift as a modifier for a key, a mouse button or a second modifier MUST keep
  the layout.
- **FR-003**: Two Shift taps in the double-tap interval MUST replace the last word and the
  spaces after it. The new text is the same keys in the layout that the first tap selected.
- **FR-004**: The app MUST keep only the current word. The app MUST clear the word when an
  event can move the caret.
- **FR-005**: On Space or Return the app MUST examine the completed word. If the detector
  agrees, the app MUST replace the word and change the layout before it sends the Space or
  the Return.
- **FR-006**: The detector MUST use a dictionary and a character trigram model for each
  language. The detector MUST keep a frequent word of the current layout.
- **FR-007**: The app MUST remember a word that the user reverted after an automatic
  correction. The app MUST keep that word as typed from then on.
- **FR-008**: The user MUST be able to set automatic correction to off for all apps and for
  one app.
- **FR-009**: The app MUST run as a menu bar item with no Dock icon. The app MUST be able to
  start at login.
- **FR-010**: The typed text MUST stay in memory only. The app MUST keep it out of the disk,
  the log and the network.

### Key entities

- **Keystroke**: a key code with the state of Shift and Caps Lock. It is independent of the
  layout.
- **Word buffer**: the keystrokes of the current word and of the spaces after it.
- **Language model**: a dictionary with word ranks and a trigram table for one language.
- **Exceptions**: the words that the user reverted. The app stores the words, not the typing
  history.

## Success criteria

### Measurable outcomes

The tests in `Tests/KeySwitchCoreTests/AccuracyTests.swift` enforce SC-001, SC-002 and SC-003.
The values in parentheses are the measured results for Russian and English.

- **SC-001**: The detector changes less than 0.5% of correctly typed words that are absent
  from the dictionary (0.10% and 0.06%). For the 20,000 most frequent words the limit is 0.1%
  (0.05% and 0.03%), and 0% for the first 8000.
- **SC-002**: The user types the 20,000 most frequent words of each language in the
  incorrect layout. The detector corrects 95% or more of them (96.9% and 96.1%). For words
  that are absent from the dictionary the limit is 90% (92.1% and 91.4%).
- **SC-003**: One decision of the detector takes less than 50 microseconds (15 microseconds).
- **SC-004**: One gesture converts a word. One gesture reverts the conversion.

## Assumptions

- The user has one Latin layout and one Cyrillic layout. The first version has models for
  English and Russian only.
- The Mac App Store is not possible for this app. A global event tap needs the Accessibility
  permission, and the sandbox prevents that.
- The word frequency lists come from the FrequencyWords project (OpenSubtitles 2018).
- Some pairs are words in the two languages, for example `vs` and `мы`. The detector prefers
  the much more frequent word. The user reverts an incorrect choice with a double Shift tap.
