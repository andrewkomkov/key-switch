# KeySwitch Constitution

## Core principles

### I. Private by construction

KeySwitch reads each key that the user presses. The word buffer stays in memory and holds
the current word only. KeySwitch MUST keep keystrokes out of the disk, the log and the
network. The app makes no network requests.

### II. Keep the text of the user safe

A conversion replaces text that the user typed. The gesture for a manual conversion MUST
also revert each automatic conversion. After the user reverts a word, the app MUST keep that
word as typed. When the detector is not sure, it does nothing.

### III. Detection is a pure, tested library

The decision to convert a word is in `KeySwitchCore`. This library is free of AppKit, of
event taps and of global state. Tests measure its accuracy on words that the dictionary does
not have. The tests enforce a limit for incorrect conversions. A change of a threshold MUST
keep the tests green.

### IV. Native, small, free of dependencies

The app uses Swift and system frameworks only. The interface is SwiftUI and follows the
current macOS design. The detector must give its decision in much less than a millisecond,
because the typing path waits for it.

### V. Spec first

Each change goes through spec-kit. A numbered folder in `specs/` with `spec.md`, `plan.md`
and `tasks.md` comes before the code. A ticked task tells that the code exists and that a
check passed.

## Release and workflow

- Commits follow Conventional Commits 1.0.0. The release-please action calculates the
  versions and writes the changelog from the commits.
- The `main` branch is always ready for a release. CI builds the app and runs the tests on
  each push and on each pull request.
- Large changes go into stacked pull requests.

## Governance

This constitution is more important than convenience. An amendment is a pull request that
changes this file and gives the reason. The amendment also changes the version below.

**Version**: 1.0.0 | **Ratified**: 2026-10-09 | **Last Amended**: 2026-10-09
