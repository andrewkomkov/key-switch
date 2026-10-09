# Feature Specification: Stable local signing

**Feature Branch**: `002-stable-signing`

**Created**: 2026-10-09

**Status**: Implemented

<!-- ste: all — the words of the user, kept as written -->
**Input**: User description: "Why does it ask for access in Accessibility after each reinstall?"

## User scenarios and tests

### User Story 1: The permission stays after a new build (Priority: P1)

The developer builds the app again and installs it. The app works immediately. macOS does not
ask for the Accessibility permission a second time.

**Why this priority**: With an ad-hoc signature, each build needs a new permission. This
makes each test of a change slow.

**Independent Test**: Give the permission to one build. Change the source. Build the app.
Install the new build. The log of the app shows `Event tap installed`, and the developer did
nothing in System Settings.

**Acceptance Scenarios**:

1. The local identity exists and one build has the permission. If the developer installs a
   new build, the event tap starts without a new permission.
2. The local identity is absent. If the developer builds the app, the script signs ad hoc as
   before.
3. `SIGN_IDENTITY` has a value. If the developer builds the app, the script uses that value.

### User Story 2: The per-app exclusion has a test (Priority: P2)

Task T018 of feature 001 stayed open because no test examined the per-app exclusion.
The end-to-end test gets a scenario for it.

**Independent Test**: The end-to-end test excludes its own app and types `ghbdtn` and Space.
The text stays `ghbdtn `.

### Edge cases

- The identity is self-signed. It does not help with Gatekeeper on a different Mac. Releases
  from CI stay ad hoc.
- The password of the keychain is in the script. The keychain holds only this one key, and
  the key signs nothing but local builds.

## Requirements

### Functional requirements

- **FR-001**: A script MUST create a self-signed code signing identity in a keychain of its
  own. The script MUST leave the login keychain and the keychain search list as they are.
- **FR-002**: The build script MUST sign with the local identity when it exists and
  `SIGN_IDENTITY` is empty.
- **FR-003**: The designated requirement of the app MUST be the same for each build.
- **FR-004**: The exclusion MUST use the app that gets the keys, also when that app is
  KeySwitch.

## Success criteria

### Measurable outcomes

- **SC-001**: After one permission, a new build starts its event tap in less than 30 seconds
  with no action from the user.
- **SC-002**: The end-to-end test passes with the exclusion scenario.

## Assumptions

- macOS identifies a self-signed app by its designated requirement: the bundle identifier
  and the hash of the certificate.
