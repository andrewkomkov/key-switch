# Data Model: Typo correction

## TypoPolicy.Candidate

A word that the app can send to the spelling checker.

| Field | Type | Rule |
| --- | --- | --- |
| `prefix` | String | The characters before the first letter |
| `core` | String | Letters only, 3 or more, no capital letter after the first one |
| `suffix` | String | The characters after the last letter |

## Typo correction state in the engine

| Field | Type | Meaning |
| --- | --- | --- |
| `typed` | String | The text that the user typed, with punctuation |
| `shown` | String | The text on the screen after the correction |

State transitions of the word buffer:

1. The user completes a word. The app corrects it. The buffer gets the mark `typoCorrected`.
2. Space adds to the spaces after the word. The mark stays.
3. A double Shift tap reverts the text and clears the mark. The word becomes an exception.
4. Backspace or a new word clears the buffer and the mark.

## Settings

| Key | Type | Default |
| --- | --- | --- |
| `fixTypos` | Bool | false |
