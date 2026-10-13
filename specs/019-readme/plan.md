# Implementation Plan: README for a new visitor

**Branch**: `019-readme` | **Date**: 2026-10-13 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

The top of `README.md` becomes a landing part: icon, description, badges, installation,
table of functions, reasons. The reference sections stay below it. A new file,
`README.ru.md`, is a short Russian guide.

## Technical Context

**Language and version**: Markdown with the HTML that GitHub permits.

**Primary Dependencies**: The badge images of shields.io and of GitHub Actions.

**Testing**: A look at the two pages on GitHub.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| First screen | Icon, example, badges, Homebrew command | A visitor decides in some seconds |
| Functions | One table: action, result, default | Faster to read than 10 sections |
| Russian page | A short guide, not a full translation | A full copy becomes stale. The details stay in one file |
| Emoji in the text | None | The repository rule. The table gives the name of the emoji |
| Image of the icon | `docs/icon.png` from feature 018 | One source, the icon script |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The badges load only in the browser of the visitor. |
| II. Keep the text of the user safe | Pass. No change in the app. |
| III. Detection is a pure, tested library | Pass. No change in the library. |
| IV. Native, small, free of dependencies | Pass. No change in the app. |
| V. Spec first | Pass. |

## Project Structure

```text
README.md        landing part, then the reference sections
README.ru.md     short Russian guide
```
