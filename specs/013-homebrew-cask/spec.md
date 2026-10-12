# Feature Specification: Installation with Homebrew

**Feature Branch**: `013-homebrew-cask`

**Created**: 2026-10-12

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "выложи в brew и подвяжи github чтоб он как-то обновлял brew или
как оно должно работать?" The user selected: export the current signing key for the releases.

## User scenarios and tests

### User Story 1: One command installs the app (Priority: P1)

The user runs `brew install --cask andrewkomkov/tap/key-switch`. Homebrew downloads the
release, checks its hash and puts `KeySwitch.app` in `/Applications`. The app starts with no
Gatekeeper message.

**Why this priority**: The manual installation has 5 steps, and one of them is a terminal
command that removes the quarantine mark.

**Independent Test**: Run the command on a Mac that has Homebrew. Open the app.

**Acceptance Scenarios**:

1. If the user runs the install command, `/Applications/KeySwitch.app` has the version of
   the latest release.
2. If the user opens the installed app, macOS shows no quarantine message.
3. If the user runs `brew uninstall --cask key-switch`, the app stops and goes away.

### User Story 2: A release updates the cask (Priority: P1)

The maintainer merges the release pull request. The release workflow builds the app, uploads
the archive and writes the new version and hash to the cask. The maintainer does nothing by
hand.

**Why this priority**: A cask that a person must edit goes out of date.

**Acceptance Scenarios**:

1. If a release appears, the cask in the tap gets its version and its hash. This takes not
   more than 10 minutes.
2. If the user then runs `brew upgrade --cask key-switch`, the new version replaces the old
   one.

### User Story 3: The permission stays after an upgrade (Priority: P2)

The user gave the Accessibility permission to one release. After `brew upgrade`, the app
works with no new permission.

**Why this priority**: With an ad-hoc signature, each upgrade needs a new permission.

**Acceptance Scenarios**:

1. Two releases have the same designated requirement in their signatures.
2. A release and a local build with the local identity have the same designated requirement.
3. The signing secret is absent, for example in a fork. The workflow signs ad hoc and
   does not fail.

### Edge cases

- `/Applications/KeySwitch.app` from a manual installation exists. Homebrew reports this.
  The user removes the app or adds `--force`.
- Apple did not notarize the app. The cask removes the quarantine mark after the install.
- The push to the tap fails. The release stays valid, and the workflow run shows the error.
- Homebrew stops the app before an upgrade. The user opens it again.

## Requirements

### Functional requirements

- **FR-001**: A public tap MUST have a cask for KeySwitch with the version, the hash and the
  address of the release archive.
- **FR-002**: The release workflow MUST write the version and the hash of each new release
  to the cask.
- **FR-003**: The cask MUST remove the quarantine mark from the installed app.
- **FR-004**: The release workflow MUST sign the app with the identity from the repository
  secret. If the secret is absent, the workflow MUST sign ad hoc.
- **FR-005**: The secrets MUST stay out of the repository and out of the workflow log.
- **FR-006**: The README MUST give the install, upgrade and uninstall commands.

## Success criteria

### Measurable outcomes

- **SC-001**: `brew audit --cask` and `brew style` report no error for the cask.
- **SC-002**: The first release after this feature updates the cask with no manual step.
- **SC-003**: The app from Homebrew starts its event tap on the Mac of the maintainer with
  no new permission.

## Assumptions

- The tap is a different repository, `andrewkomkov/homebrew-tap`. The workflow writes to it
  with a deploy key that has access to this one repository only.
- The signing identity is self-signed. A person who has its key can sign an app that gets
  the permission of KeySwitch. The key is in a repository secret and in the local keychain.
- The app itself makes no network connection. Homebrew looks for the updates.
