# Feature Specification: README for a new visitor

**Feature Branch**: `019-readme`

**Created**: 2026-10-13

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "репа публичная же? Readme там красивый и рекламный? Типо понятно че и как ставить и юзать?"

## User scenarios and tests

### User Story 1: A visitor decides in one screen (Priority: P1)

A person opens the public repository. The first screen must tell this person three things:
what the app does, why it is good, and how to install it. The old README starts with a
table of gestures and gives the installation command only after 30 lines.

The new first screen has the icon, one line with an example, the badges, and the
installation command. A table of functions with examples comes next.

**Why this priority**: The README is the only page that a visitor reads.

**Independent Test**: Open the repository page on GitHub. Do not scroll. The page shows the
name, the example `ghbdtn`, and the Homebrew command.

**Acceptance Scenarios**:

1. The top of the README shows the icon, the name and a one-line description with an example.
2. The installation command is in the first section.
3. One table shows each function with an example and its default state.
4. Each number in the promotional text agrees with the tests or with the built app.
5. The reference sections of the old README stay.

### User Story 2: A Russian reader gets a Russian page (Priority: P2)

Most persons who need a Russian and English layout switcher read Russian. The file
`README.ru.md` gives them the short guide: installation, functions, gestures. The two
files link to each other.

**Independent Test**: Click the link to the Russian page at the top of the README. The
Russian page opens and has the installation command.

## Requirements

### Functional requirements

- **FR-001**: The README MUST start with the icon, the description and the installation.
- **FR-002**: The README MUST keep all reference sections of the old file.
- **FR-003**: `README.ru.md` MUST have the installation, the functions and the gestures.
- **FR-004**: The description of the repository on GitHub MUST name the current functions.

## Success criteria

### Measurable outcomes

- **SC-001**: The images and the links of the two files work on GitHub.
- **SC-002**: The defaults in the table agree with `Sources/KeySwitch/Settings.swift`.

## Assumptions

- The top of the README is promotional text. The STE rules do not apply to it. The
  reference sections stay in STE.
- The page has no screen recording. A recording is a possible later addition.
