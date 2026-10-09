# Research: Typo correction

## Source of the correction

**Decision**: `NSSpellChecker.correction(forWordRange:in:language:inSpellDocumentWithTag:)`.

**Rationale**: This call gives the correction that macOS applies in its own text fields. It
gives a result only when the system is sure. A test on this Mac gave these results:

| Typed word | Language | Correction |
| --- | --- | --- |
| `teh` | en | `the` |
| `recieve` | en | `receive` |
| `definately` | en | `definitely` |
| `севодня` | ru | `сегодня` |
| `агенство` | ru | `агентство` |
| `kubectl` | en | none |
| `превет` | ru | none |
| `карова` | ru | none |

**Alternatives considered**:

- `guesses(forWordRange:)`: it gives a list for almost each word, for example `какова` for
  `карова`. The first item is frequently incorrect.
- A correction from the word lists of feature 001 with edit distance: no data about
  frequent typos, thus more incorrect changes.

## Cost of the call

**Decision**: skip the call for the 15,000 most frequent words of the language.

**Rationale**: the call goes to a system service and takes from 10 to 70 milliseconds. Most
typed words are frequent words, and a lookup in the list takes less than a microsecond.

## Frequency check

**Decision**: accept a correction only when it is a word of the frequency list. If the typed
word is also in the list, the correction must be 2 times more frequent. A bundled list of
technical terms stays as typed.

**Rationale**: the tests found two problems.

- The frequency list comes from subtitles and has frequent misspellings, for example
  `агенство` at rank 19,864. A word of the list is thus not always correct.
- The checker is sometimes sure and incorrect for new words: `pytest` gave `purest`, and
  `бэкенд` gave `бэкхенд`. The first is a technical term. The second correction is not in
  the frequency list.

## Limits on a correction

**Decision**: accept a correction of one word with an edit distance of 1 or 2. A swap of two
adjacent letters is one edit.

**Rationale**: frequent typos are one or two edits. A longer distance means a different word.

## Revert

**Decision**: keep the original and the corrected text until the subsequent word. On a
double Shift tap, type the original text again and select the layout from before the taps.

**Rationale**: the first tap of the gesture changes the layout. The typo was in the correct
layout, thus the revert must select that layout again.
