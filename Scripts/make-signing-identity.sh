#!/bin/bash
# Creates a self-signed code signing identity in its own keychain. build-app.sh signs with
# it, so that macOS keeps the Accessibility permission when the app is built again.
# SIGNING_P12_BASE64  an identity to import in place of a new one: base64 of a PKCS#12 file
#                     with the password "keyswitch". The release workflow sets it.
set -euo pipefail

keychain="$HOME/Library/Keychains/keyswitch-signing.keychain-db"
name="KeySwitch Local Signing"
# Not a secret: the keychain holds only this throwaway key.
password=keyswitch

if [[ -f "$keychain" ]]; then
    echo "The identity exists: $keychain"
    exit 0
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cat > "$work/cert.cnf" <<EOF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $name
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF

if [[ -n "${SIGNING_P12_BASE64:-}" ]]; then
    base64 --decode <<< "$SIGNING_P12_BASE64" > "$work/identity.p12"
else
    # The system LibreSSL writes a PKCS#12 file that `security import` can read.
    /usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config "$work/cert.cnf" \
        -keyout "$work/key.pem" -out "$work/cert.pem" 2>/dev/null
    /usr/bin/openssl pkcs12 -export -inkey "$work/key.pem" -in "$work/cert.pem" \
        -name "$name" -passout "pass:$password" -out "$work/identity.p12"
fi

security create-keychain -p "$password" "$keychain"
security set-keychain-settings "$keychain"
security unlock-keychain -p "$password" "$keychain"
security import "$work/identity.p12" -k "$keychain" -P "$password" -T /usr/bin/codesign >/dev/null
security set-key-partition-list -S apple-tool:,apple: -s -k "$password" "$keychain" >/dev/null
security find-identity -p codesigning "$keychain"

echo "The identity \"$name\" is in $keychain"
