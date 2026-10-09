# Implementation Plan: Layout switcher

**Branch**: `001-layout-switcher` | **Date**: 2026-10-09 | **Spec**: [spec.md](spec.md)

## Summary <!-- slop: heading of the spec-kit template -->

KeySwitch is a menu bar app for macOS. A global event tap reads the keys. A Shift tap
selects the next layout. A double Shift tap types the last word again in the other layout.
A detector looks at each completed word and converts the word if the user typed it in the
incorrect layout.

## Technical Context

**Language and version**: Swift 6 (Xcode 27)

**Primary Dependencies**: SwiftUI, AppKit, CoreGraphics event taps, Carbon Text Input
Sources, ServiceManagement. No third-party packages.

**Storage**: `UserDefaults` for the settings and for the exception words.

**Testing**: Swift Testing through `swift test`.

**Target Platform**: macOS 26 and later, built with the macOS 27 SDK, Apple silicon and Intel.

**Project Type**: desktop app, built as a Swift package and assembled into `KeySwitch.app`.

**Performance Goals**: the detector uses less than 50 microseconds for each word.

**Constraints**: the app stays off the network and off the Dock. Keystrokes stay in memory.

## Research: automatic detection

The search found four methods in existing programs.

| Method | Used by | Result |
| --- | --- | --- |
| Dictionary only | Bzz, old Punto Switcher | Misses words that are not in the dictionary |
| Character n-gram model | Rekey, XNeur | Fast, handles unknown words, makes errors on short words |
| System spelling checker | small utilities | One XPC call for each word, slow and not deterministic |
| Neural network | Caramba Switcher (not documented) | No public model, more latency, small gain for one word |

Decision: a dictionary together with a character trigram model for each language.

- The dictionary gives an exact answer for frequent words.
- The trigram model gives an answer for words that are not in the dictionary. It tells a
  plausible word from a string of random letters.
- The two parts use one frequency list for each language. The app builds the trigram table
  from that list when it starts. The repository holds no generated model file.
- A neural model does not help here. The input is one word of 2 to 15 characters. The
  trigram model already separates the two layouts on such input, and a table lookup is
  about 1000 times faster than a network.

Decision rule for a completed word:

1. Read the keys in the current layout and in the other layout.
2. Stop if the word has a digit, has one letter, or is an exception word.
3. If the two readings are dictionary words, compare their ranks. Convert only a current
   reading below rank 8000 that is 10 times rarer than the other reading. Stop.
4. Stop if the current reading is a dictionary word.
5. Convert if the other reading is a dictionary word. A reading of 2 or 3 letters must be
   one of the 5000 most frequent words.
6. For two unknown readings, use the trigram scores. The conditions are in the table below.

| Condition for step 6 | Value |
| --- | --- |
| The other reading has letters only | Yes |
| Length of the other reading | 4 letters or more |
| Mean log probability of the other reading | -3.4 or more |
| Difference between the two scores | 1.2 or more |
| A frequent word inside the current reading | Absent |

A grid search on words that the dictionary does not have gave these thresholds. The same
words measure the result in `AccuracyTests.swift`.

The English dictionary also includes `Resources/en-tech.txt`. This list has technical terms
that are absent from film subtitles, for example `http` and `kubectl`.

## Constitution Check

| Principle | Status |
| --- | --- |
| I. Private by construction | Pass. The buffer holds one word in memory. No network code. |
| II. Keep the text of the user safe | Pass. A double Shift tap reverts each conversion. |
| III. Detection is a pure, tested library | Pass. `KeySwitchCore` has no AppKit import. |
| IV. Native, small, free of dependencies | Pass. System frameworks only. |
| V. Spec first | Pass. This folder exists before the code. |

## Project Structure

```text
Package.swift
Sources/
  KeySwitchCore/        pure logic, no AppKit
    LanguageModel.swift   dictionary and trigram table
    Detector.swift        decision rule
    WordBuffer.swift      current word as keystrokes
    ShiftTapRecognizer.swift  single tap and double tap state machine
  KeySwitch/            the app
    KeySwitchApp.swift    SwiftUI entry: MenuBarExtra, Settings, onboarding window
    Engine.swift          event tap and the reaction to each event
    InputSources.swift    layouts: list, select, translate key codes
    Typist.swift          posts Backspace keys and Unicode text
    Settings.swift        observable settings in UserDefaults
    SelfTest.swift        end-to-end test with real key events
    Views/                SwiftUI views
Tests/KeySwitchCoreTests/
Resources/              ru.txt and en.txt frequency lists, Info.plist, icon
Scripts/                build-app.sh, make-wordlists.py, make-icon.swift
.github/workflows/      ci.yml, release.yml
```

**Structure Decision**: one Swift package with a library target and an executable target.
A script assembles the `.app` bundle, because a Swift package cannot make one.

## Complexity Tracking

No violations.
