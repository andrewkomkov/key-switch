# Implementation Plan: Clipboard history at the top of the menu

**Branch**: `020-clipboard-on-top` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

`MenuView` moves the block `if settings.clipboardHistory { … }` above the switches. The
divider moves from before the block to after it.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: SwiftUI.

**Storage**: None.

**Testing**: The end-to-end test cannot open the menu. A manual check is necessary.

## Decisions

| Question | Decision | Reason |
| --- | --- | --- |
| Accessibility item | Stays first | It is a warning, and the app does not work without the access |
| Search item | Stays the first item of the clipboard part | The user sees it before the long list |

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. No new data. |
| II. Keep the text of the user safe | Pass. Only the order of the items changes. |
| III. Detection is a pure, tested library | Pass. No change in the library. |
| IV. Native, small, free of dependencies | Pass. |
| V. Spec first | Pass. |

## Project Structure

```text
Sources/KeySwitch/
  Views/MenuView.swift             order of the menu parts
```
