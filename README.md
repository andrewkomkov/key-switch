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

## Requirements

- macOS 26 or later.
- One English layout and one Russian layout in System Settings.
- The Accessibility permission. KeySwitch needs it to read the keys and to type the correction.

## Installation from a release

1. Download `KeySwitch.zip` from the [releases](https://github.com/andrewkomkov/key-switch/releases).
2. Move `KeySwitch.app` to `/Applications`.
3. Remove the quarantine mark: `xattr -dr com.apple.quarantine /Applications/KeySwitch.app`.
4. Open the app.
5. Give the Accessibility permission.

Step 3 is necessary because the release has an ad-hoc signature. Apple did not notarize it.

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

## Privacy

- KeySwitch keeps the keys of the current word in memory. It deletes them when the caret moves.
- The keys stay out of the disk and out of the log.
- KeySwitch makes no network connections.
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

The code has the [MIT license](LICENSE). The word lists have the CC BY-SA 4.0 license.
See [Resources/NOTICE.md](Resources/NOTICE.md).
