# KeySwitch

KeySwitch is a keyboard layout switcher for macOS, like Punto Switcher and Caramba Switcher.
It is a native menu bar app in Swift and SwiftUI. It uses system frameworks only and makes
no network connections.

| Gesture | Result |
| --- | --- |
| Tap Shift | The next keyboard layout becomes active. |
| Tap Shift two times | KeySwitch types the last word again in the other layout: `ghbdtn` becomes `привет`. |
| Type a word in the incorrect layout, then press Space or Return | KeySwitch corrects the word and changes the layout. |
| Tap Shift two times after an automatic correction | The original word comes back. KeySwitch adds the word to the exceptions. |
| Tap Shift three times or more in one series | Each tap after the second one converts one more word to the left. |
| Tap Option two times | The case of the last word changes: `hello`, `Hello`, `HELLO`. A word such as `hELLO` becomes `Hello`. |
| Press Command-Shift-V | KeySwitch pastes the text of the clipboard without its format. |

The Shift gesture and the Option gesture also work on selected text. Select the text.
Then use the gesture before you type. KeySwitch reads the selection through the Accessibility
API. If an app gives no answer, KeySwitch copies the selection, pastes the result, and puts
the old content back in the clipboard.

Command-Shift-V works in each app that accepts Command-V. The clipboard keeps its original
content. If the clipboard has no text, the front app gets the shortcut. An app in the list
of excluded apps also keeps its own function for this shortcut.

## Requirements

- macOS 26 or later.
- One English layout and one Russian layout in System Settings.
- The Accessibility permission. KeySwitch needs it to read the keys and to type the correction.

## Installation with Homebrew

```sh
brew install --cask andrewkomkov/tap/key-switch
open -a KeySwitch
```

Then give the Accessibility permission.

| Task | Command |
| --- | --- |
| Get a new version | `brew upgrade --cask key-switch` |
| Remove the app | `brew uninstall --cask key-switch` |
| Remove the app and its data | `brew uninstall --cask --zap key-switch` |

Homebrew stops the app before an upgrade. Open the app again after it. The permission stays,
because each release has the same signature. The release workflow writes each new version to
the [tap](https://github.com/andrewkomkov/homebrew-tap).

## Installation from a release

1. Download `KeySwitch.zip` from the [releases](https://github.com/andrewkomkov/key-switch/releases).
2. Move `KeySwitch.app` to `/Applications`.
3. Remove the quarantine mark: `xattr -dr com.apple.quarantine /Applications/KeySwitch.app`.
4. Open the app.
5. Give the Accessibility permission.

Step 3 is necessary because the release has a self-signed signature. Apple did not notarize
it. The Homebrew cask does this step for you.

## Installation from the source

```sh
git clone https://github.com/andrewkomkov/key-switch.git
cd key-switch
./Scripts/build-app.sh
cp -R build/KeySwitch.app /Applications/
open /Applications/KeySwitch.app
```

The script signs the app ad hoc. After each new ad-hoc build, macOS asks for the
Accessibility permission again, because the permission belongs to the hash of the binary.

To keep the permission, run `./Scripts/make-signing-identity.sh` one time before the build.
The script makes a self-signed identity in a keychain of its own. The build script then
signs each build with this identity, and macOS identifies all builds as one app.
As an alternative, set `SIGN_IDENTITY` to a valid signing identity.

A revoked certificate is dangerous here. Gatekeeper reports an app with such a signature as
malware and moves the app to the Trash.

## Automatic detection

KeySwitch reads each completed word in the two layouts and compares the two readings.

1. A dictionary gives the answer for frequent words: 100,000 Russian and 50,000 English words.
2. A character trigram model gives the answer for words that are not in the dictionary. The
   model tells a possible word from a string of random letters.
3. Sometimes the two readings are words. Then KeySwitch converts only a rare current reading
   into a much more frequent one.

KeySwitch ignores a word that has a digit, a word of one letter, and an exception word.

These are the results of `swift test`:

| Measurement | Russian | English |
| --- | --- | --- |
| Incorrect-layout words that KeySwitch corrects, 20,000 most frequent words | 96.9% | 96.1% |
| Incorrect-layout words that KeySwitch corrects, 10,000 words that the dictionary does not have | 92.1% | 91.4% |
| Correct words that KeySwitch changes, 20,000 most frequent words | 0.05% | 0.03% |
| Correct words that KeySwitch changes, 10,000 words that the dictionary does not have | 0.10% | 0.06% |

One decision takes about 15 microseconds in a debug build.

The file `specs/001-layout-switcher/plan.md` compares this method with three alternatives:
a dictionary only, the system spelling checker, and a neural network.

## Accidental capitals

This option is on by default. The switch is "Fix accidental capitals" in the settings.

When you complete a word with two capitals at the start, KeySwitch keeps only the first
one: `ПРивет` becomes `Привет`. A word with the inverted pattern, such as `hELLO`, becomes
`Hello`. KeySwitch changes only a word that its dictionary has. Thus `OSes`, `IDs` and `МВт`
stay as typed. A word in capitals only also stays.

Tap Shift two times to get the typed word back. The word then becomes an exception.

## Capital at the start of a sentence

This option is off by default. Set "Capitalize the first word of a sentence" to on in the
settings.

macOS gives this capital only in the apps that use its text system. KeySwitch gives it in
each app. When you complete a word after `.`, `!` or `?` and a space, the word gets a capital
first letter: `Привет. как` becomes `Привет. Как`.

KeySwitch keeps the word as typed in these cases:

- The word before it is an abbreviation, such as `etc.` or `т.е.`, or one letter.
- The word before it ends with an ellipsis.
- The word has a capital, a digit or a symbol in it.
- You moved the caret, or the word is the first one of a new line. KeySwitch knows only the
  phrase that you typed.

Tap Shift two times to get the typed word back. The word then becomes an exception.

## Typo correction

This option is off by default. Set "Fix typos" to on in the settings.

When you complete a word, KeySwitch asks the macOS spelling checker for a sure correction:
`recieve` becomes `receive`, and `севодня` becomes `сегодня`. KeySwitch accepts the
correction only when it is a frequent word and is 1 or 2 edits from the typed word.

KeySwitch keeps these words as typed:

- a word with a digit
- a word of fewer than 3 letters
- a word with a capital letter after the first letter
- a technical term such as `kubectl`

Tap Shift two times to get the typed word back. The word then becomes an exception.

## The letter ё

This option is off by default. Set "Put the letter ё back" to on in the settings.

When you complete a Russian word, KeySwitch puts `ё` in place of `е` if the word always has
`ё`. For example, `еще` becomes `ещё`, and `зеленый` becomes `зелёный`. A word with two correct spellings
stays as typed, for example `все`. The same rule applies to a word that KeySwitch converts
from the English layout.

The list has 106,654 word forms. It comes from the
[eyo-kernel](https://github.com/e2yo/eyo-kernel) project.

Tap Shift two times to get the typed word back. The word then becomes an exception.

## Text replacements

This option is on by default. The switch is "Use the text replacements of macOS in all
apps" in the settings.

macOS has a list of text replacements in System Settings, Keyboard, Text Replacements. For
example, `omw` becomes `On my way!`. Some apps ignore the list: a Chromium browser, an
Electron app, a terminal. KeySwitch reads the list of macOS and applies it in each app when
you complete the shortcut with Space or Return. KeySwitch has no list of its own. Change the
list in System Settings.

KeySwitch ignores a shortcut with a space in it and a phrase with a line break.

Tap Shift two times to get the shortcut back. The shortcut then becomes an exception.

## Emoji codes

This option is on by default. The switch is "Replace emoji codes such as :fire:" in the
settings.

An emoji code is a name between two colons: `:fire:`, `:+1:`, `:heart:`. When you complete
a code with the Space key, KeySwitch puts the emoji in place of the code. The list has the 1,913 codes of GitHub and
comes from the [gemoji](https://github.com/github/gemoji) project. The code also works when
a Russian layout is active: press the same keys as for the English layout.

Tap Shift two times to get the code back. The name of the code then becomes an exception.

## Learned words

This option is off by default. Set "Learn the words that I type often" to on in the settings.

The dictionary comes from film subtitles and does not have your work words. KeySwitch learns
a word in two cases:

- You type an unknown word three times in one session, and its other reading is not a word.
- You convert a word with a double Shift tap.

A learned word counts as a frequent dictionary word. For example, after you learn `гит`,
KeySwitch converts `ubn` to `гит`. The "Learned" tab of the settings shows the list. You can
remove each word there.

## Clipboard history

This option is off by default. Set "Keep a clipboard history" to on in the "Clipboard" tab
of the settings.

KeySwitch then keeps the text and the images that you copy. The menu of KeySwitch in the
menu bar shows the entries, the newest first. Click an entry to put it in the clipboard
again. The history holds 10, 25, 50 or 100 entries and stays after a restart.

The history ignores these items:

- an item that a password manager marks as concealed
- copied files
- the clipboard changes that KeySwitch makes for its own functions
- text longer than 200,000 characters and an image larger than 20 MB

The entries are in `~/Library/Application Support/KeySwitch/Clipboard`. Only your user
account can read this folder. "Clear History" deletes the entries and the image files.

To search the history:

1. Press Control-Option-V. A panel opens with a search field and the list of entries.
   The item "Search the History…" in the menu opens the same panel.
2. Type some words of the entry.
3. Select the entry with the arrow keys.
4. Press Return. KeySwitch pastes the entry into the front app.

Escape closes the panel. The switch for this shortcut is "Search the history with ⌃⌥V".

To keep an entry, pin it. There are two procedures:

- Hold Option. Then click the entry in the menu.
- Click the pin of the entry in the "Clipboard" tab.

The menu shows the pinned entries in their own group. The limit and "Clear History" do not
delete a pinned entry. A second Option-click removes the pin.

## Privacy

- KeySwitch keeps the keys of the current word in memory. It deletes them when the caret moves.
- The keys stay out of the disk and out of the log. The disk gets only single words: the
  exceptions, and the learned words when learning is on.
- KeySwitch makes no network connections.
- With the clipboard history on, the content that you copy is on the disk of this Mac. A
  password that an app copies without the concealed mark goes into the history.
- With typo correction on, a rare word goes to the spelling checker of macOS on this Mac.
- macOS hides the keys of password fields from KeySwitch.

## Development

```sh
swift test                    # unit tests and accuracy tests
./Scripts/build-app.sh        # build/KeySwitch.app
```

The end-to-end test types real key events into a window of the app and checks the text.
It needs the Accessibility permission and exactly two layouts, English and Russian.

```sh
pkill -x KeySwitch
open -W /Applications/KeySwitch.app --args --self-test /tmp/keyswitch-report.txt
cat /tmp/keyswitch-report.txt
```

Each change goes through [spec-kit](https://github.com/github/spec-kit). See `specs/` and
`.specify/memory/constitution.md`. Commits follow Conventional Commits.
The [release-please](https://github.com/googleapis/release-please) action makes the releases.

## License

The code has the [MIT license](LICENSE). The frequency lists have the CC BY-SA 4.0 license.
See [Resources/NOTICE.md](Resources/NOTICE.md).
