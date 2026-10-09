# Word list notice

The MIT license of this repository applies to the code. A different license applies to these files:

- `Resources/ru.txt`
- `Resources/en.txt`
- `Tests/KeySwitchCoreTests/Fixtures/ru-heldout.txt`
- `Tests/KeySwitchCoreTests/Fixtures/en-heldout.txt`

These files come from [FrequencyWords](https://github.com/hermitdave/FrequencyWords) by
Hermit Dave, folder `content/2018`. The source of the counts is the OpenSubtitles 2018 corpus.
The license of the files is [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

Changes: `Scripts/make-wordlists.py` keeps the words that have only letters of the language.
The script keeps the first 100,000 Russian words and the first 50,000 English words. The
script puts the subsequent 10,000 words of each language in the test fixtures.
