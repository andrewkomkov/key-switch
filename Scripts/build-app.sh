#!/bin/bash
# Builds build/KeySwitch.app.
# SIGN_IDENTITY  signing identity, default ad-hoc. An ad-hoc signature loses the Accessibility
#                permission on each rebuild. A revoked certificate makes Gatekeeper trash the app.
# ARCHS          architectures to build, default the architecture of this Mac.
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(tr -d '[:space:]' < version.txt)
app=build/KeySwitch.app

arch_flags=()
for arch in ${ARCHS:-}; do arch_flags+=(--arch "$arch"); done
swift build -c release ${arch_flags[@]+"${arch_flags[@]}"}
bin_dir=$(swift build -c release ${arch_flags[@]+"${arch_flags[@]}"} --show-bin-path)

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/KeySwitch" "$app/Contents/MacOS/"
sed "s/__VERSION__/$version/g" Resources/Info.plist > "$app/Contents/Info.plist"
cp Resources/AppIcon.icns Resources/ru.txt Resources/en.txt Resources/en-tech.txt "$app/Contents/Resources/"
cp -R Resources/en.lproj Resources/ru.lproj "$app/Contents/Resources/"

local_keychain="$HOME/Library/Keychains/keyswitch-signing.keychain-db"
if [[ -z "${SIGN_IDENTITY:-}" && -f "$local_keychain" ]]; then
    security unlock-keychain -p keyswitch "$local_keychain"
    codesign --force --options runtime --keychain "$local_keychain" --sign "KeySwitch Local Signing" "$app"
else
    codesign --force --options runtime --sign "${SIGN_IDENTITY:--}" "$app"
fi
echo "Built $app ($version)"
