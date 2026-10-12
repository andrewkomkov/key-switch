# Implementation Plan: Installation with Homebrew

**Branch**: `013-homebrew-cask` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

A new public repository, `andrewkomkov/homebrew-tap`, holds the cask. A script in this
repository writes the cask text from a version and a hash. A new job of the release workflow
runs the script and pushes the result to the tap. The build job signs the app with the
self-signed identity from a secret, so each release has the same designated requirement.

## Technical Context

**Language and version**: Bash, GitHub Actions, the Ruby cask format of Homebrew.

**Primary Dependencies**: none new in the app.

**Storage**: two repository secrets, `SIGNING_P12_BASE64` and `TAP_DEPLOY_KEY`.

**Testing**: `brew style` and `brew audit --cask` for the cask. A real install from the tap
on the Mac of the maintainer after the first release.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| Where is the cask? | A tap repository of the user | The official cask repository needs a notarized app |
| Who updates the cask? | A job of the release workflow | The update comes immediately after the archive. A timer in the tap is later by hours |
| Access to the tap | A deploy key with write access | It gives access to one repository. A personal token gives access to all of them |
| Quarantine | The cask removes the mark after the install | The app has no notarization, so Gatekeeper stops it |
| Signature of a release | The local self-signed identity, from a secret | One designated requirement for local builds and releases. The permission stays |
| No secret | Ad-hoc signature | A fork and a pull request have no secrets |
| How does CI get the identity? | `make-signing-identity.sh` imports a given PKCS#12 file | `build-app.sh` already signs with the keychain of that script |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The app makes no network request. Homebrew does the download. |
| II. Keep the text of the user safe | Not applicable. |
| III. Detection is a pure, tested library | Not applicable. |
| IV. Native, small, free of dependencies | Pass. The app has no updater. |
| V. Spec first | Pass. |

## Project Structure

```text
.github/workflows/release.yml       signing step, cask job
Scripts/make-signing-identity.sh    import of a given identity
Scripts/render-cask.sh              cask text from a version and a hash
README.md                           Homebrew commands
andrewkomkov/homebrew-tap           Casks/key-switch.rb, README.md
```
