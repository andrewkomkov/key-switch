# Implementation Plan: Stable local signing

**Branch**: `002-stable-signing` | **Date**: 2026-10-09 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

macOS stores the Accessibility permission against the code requirement of the app. For an
ad-hoc signature that requirement is the hash of the binary, and each build changes it.
A signature from a certificate gives a requirement with the bundle identifier and the
certificate hash. This requirement stays the same for each build.

## Technical Context

**Tools**: `/usr/bin/openssl` (LibreSSL), `security`, `codesign`.

**Storage**: `~/Library/Keychains/keyswitch-signing.keychain-db`.

**Testing**: the log line `Event tap installed` after a new build, and the end-to-end test.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| Where is the key? | A keychain of its own | The login keychain and the search list stay as they are |
| How does `codesign` find it? | `--keychain` with the path | The search list does not need the new keychain |
| Which `openssl`? | The system LibreSSL | `security import` cannot read the default PKCS#12 format of OpenSSL 3 |
| CI and releases | Ad hoc as before | A self-signed certificate gives no trust on a different Mac |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. No change to the typing path. |
| III. Detection is a pure, tested library | Pass. No change to `KeySwitchCore`. |
| IV. Native, small, free of dependencies | Pass. System tools only. |
| V. Spec first | Pass. |

## Project Structure

```text
Scripts/make-signing-identity.sh   creates the identity
Scripts/build-app.sh               signs with it when it exists
Sources/KeySwitch/Engine.swift     exclusion uses the app that gets the keys
Sources/KeySwitch/SelfTest.swift   scenario for the exclusion
```
