#!/bin/bash
set -euo pipefail
# This regression always exercises certificate signing, even when the build opts into ad hoc.
export VOLTA_ADHOC=0
cd "$(dirname "$0")/.."
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/volta-signing-test.XXXXXX")
cleanup() {
    security delete-keychain "$TEST_DIR/identity/signing.keychain-db" >/dev/null 2>&1 || true
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT
security list-keychains -d user > "$TEST_DIR/search-before"
export VOLTA_SIGNING_DIR="$TEST_DIR/identity"
APP="$TEST_DIR/Volta.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Helpers"
cp Info.plist "$APP/Contents/Info.plist"
for version in 1 2; do
    printf 'int main(void) { return %s; }\n' "$version" | clang -x c - -o "$APP/Contents/MacOS/Volta"
    cp "$APP/Contents/MacOS/Volta" "$APP/Contents/Helpers/spacekeeper"
    ./scripts/sign.sh "$APP"
    codesign -d -r- "$APP" 2>&1 | sed -n '/designated =>/p' > "$TEST_DIR/requirement-$version"
    codesign -d -r- "$APP/Contents/Helpers/spacekeeper" 2>&1 | sed -n '/designated =>/p' > "$TEST_DIR/helper-$version"
    codesign -d --verbose=4 "$APP" 2>&1 | sed -n 's/^CDHash=//p' > "$TEST_DIR/hash-$version"
done
# A rebuilt executable must keep both identities without binding to the old code hash.
cmp "$TEST_DIR/requirement-1" "$TEST_DIR/requirement-2"
cmp "$TEST_DIR/helper-1" "$TEST_DIR/helper-2"
if cmp -s "$TEST_DIR/hash-1" "$TEST_DIR/hash-2"; then
    echo 'Fixture did not change executable code' >&2; exit 1
fi
grep -q 'certificate' "$TEST_DIR/requirement-2"
if grep -q 'cdhash' "$TEST_DIR/requirement-2"; then
    echo 'Identity is still bound to an executable hash' >&2; exit 1
fi
# Partial identity state must fail instead of silently replacing the certificate.
mv "$VOLTA_SIGNING_DIR/password" "$TEST_DIR/password.saved"
if ./scripts/sign.sh "$APP" > "$TEST_DIR/partial-error" 2>&1; then
    echo 'Missing identity password was silently accepted' >&2; exit 1
fi
mv "$TEST_DIR/password.saved" "$VOLTA_SIGNING_DIR/password"
security list-keychains -d user > "$TEST_DIR/search-after"
cmp "$TEST_DIR/search-before" "$TEST_DIR/search-after"
echo 'Stable app/helper identity survives changed executable; partial identity fails safely.'
