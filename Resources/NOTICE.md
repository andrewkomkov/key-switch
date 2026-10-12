# Word list notice

The MIT license of this repository applies to the code.

The file `Resources/ru-yo.txt` is the "safe" dictionary of
[eyo-kernel](https://github.com/e2yo/eyo-kernel) by Denis Seleznev, without changes. It has
the MIT license of that project. The text of the license is in `Resources/ru-yo.LICENSE.txt`.

The file `Resources/emoji.txt` has the emoji codes of [gemoji](https://github.com/github/gemoji)
by GitHub. `Scripts/make-emoji-list.py` makes it from `db/emoji.json` of that project: one
line for each code. It has the MIT license of that project. The text of the license is in
`Resources/emoji.LICENSE.txt`.

A different license applies to these files:

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
