# Quickstart: Typo correction

## Prerequisites

- The English and the Russian layouts are enabled.
- KeySwitch has the Accessibility permission.

## Automatic check

```sh
swift test
./Scripts/build-app.sh
cp -R build/KeySwitch.app /Applications/
pkill -x KeySwitch
open -W /Applications/KeySwitch.app --args --self-test /tmp/keyswitch-report.txt
cat /tmp/keyswitch-report.txt
```

The report must end with `RESULT: PASS`. The scenarios with `typo` in the name are for this
feature.

## Manual check

1. Open the settings of KeySwitch.
2. Set "Fix typos" to on.
3. In a text field, type `recieve` and Space. The text becomes `receive `.
4. Tap Shift two times. The text becomes `recieve `.
5. Type `recieve` and Space again. The text stays the same.
