# Tasks: Installation with Homebrew

**Input**: [spec.md](spec.md), [plan.md](plan.md)

A ticked task means that the code exists and that a test or a manual check passed.

## Phase 1: User Story 1, one command installs the app (P1)

- [x] T001 [US1] Add `Scripts/render-cask.sh` and check its output with `brew style`
- [x] T002 [US1] Make the repository `andrewkomkov/homebrew-tap` with the cask of the current release
- [x] T003 [US1] Run `brew audit --cask` for the cask in the tap

## Phase 2: User Story 2, a release updates the cask (P1)

- [x] T004 [US2] Add a deploy key to the tap and the secret `TAP_DEPLOY_KEY` to this repository
- [x] T005 [US2] Add the cask job to `.github/workflows/release.yml`

## Phase 3: User Story 3, the permission stays (P2)

- [x] T006 [US3] Import a given identity in `Scripts/make-signing-identity.sh` and check the signature of a build
- [x] T007 [US3] Add the secret `SIGNING_P12_BASE64` and the signing step in `.github/workflows/release.yml`

## Phase 4: Delivery

- [x] T008 Give the Homebrew commands in `README.md`
- [ ] T009 Check after the first release: the cask has the new version and hash
- [ ] T010 Check after the first release: the designated requirement is the same as for a local build
- [ ] T011 Install the app from the tap on this Mac and check that the event tap starts
- [ ] T012 Check `brew upgrade` with the next release
