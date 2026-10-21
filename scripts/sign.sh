#!/bin/bash
# Keep the same local certificate across builds: TCC uses the designated requirement.
set -euo pipefail
umask 077
APP="${1:?Usage: sign.sh /path/to/Volta.app}"
if [[ "${VOLTA_ADHOC:-0}" == 1 ]]; then
    echo 'WARNING: ad hoc signatures invalidate permissions when executable code changes.' >&2
    codesign --force --sign - --identifier local.volta.engine "$APP/Contents/Helpers/spacekeeper"
    codesign --force --sign - --identifier local.volta.app "$APP"
else
    SIGNING_DIR="${VOLTA_SIGNING_DIR:-$HOME/Library/Application Support/Volta/Signing}"
    [[ "$SIGNING_DIR" == /* ]] || { echo 'VOLTA_SIGNING_DIR must be absolute.' >&2; exit 1; }
    KEYCHAIN="$SIGNING_DIR/signing.keychain-db"
    PASSWORD_FILE="$SIGNING_DIR/password"
    WORK=$(mktemp -d "${TMPDIR:-/tmp}/volta-sign.XXXXXX")
    # Creating a keychain adds it to the search list. Restore the exact original list.
    SEARCH_LIST=()
    while IFS= read -r line; do
        line="${line#*\"}"; line="${line%\"*}"
        [[ -z "$line" ]] || SEARCH_LIST+=("$line")
    done < <(security list-keychains -d user)
    RESTORE_SEARCH=0
    cleanup() {
        if [[ "$RESTORE_SEARCH" == 1 ]]; then
            security list-keychains -d user -s "${SEARCH_LIST[@]}" >/dev/null 2>&1 || true
        fi
        security lock-keychain "$KEYCHAIN" >/dev/null 2>&1 || true
        rm -rf "$WORK"
    }
    trap cleanup EXIT
    if [[ ! -d "$SIGNING_DIR" ]]; then
        mkdir -p "$SIGNING_DIR"
        openssl rand -hex 32 > "$PASSWORD_FILE"
        PASSWORD=$(cat "$PASSWORD_FILE")
        openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
            -subj '/CN=Volta Local Signing' \
            -addext 'basicConstraints=critical,CA:FALSE' \
            -addext 'keyUsage=critical,digitalSignature' \
            -addext 'extendedKeyUsage=critical,codeSigning' \
            -keyout "$WORK/key.pem" -out "$WORK/cert.pem" >/dev/null 2>&1
        openssl pkcs12 -export -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
            -out "$WORK/identity.p12" -passout "pass:$PASSWORD" >/dev/null 2>&1
        RESTORE_SEARCH=1
        security create-keychain -p "$PASSWORD" "$KEYCHAIN"
        security unlock-keychain -p "$PASSWORD" "$KEYCHAIN"
        security import "$WORK/identity.p12" -k "$KEYCHAIN" -P "$PASSWORD" -T /usr/bin/codesign >/dev/null
        security set-key-partition-list -S apple-tool:,apple: -s -k "$PASSWORD" "$KEYCHAIN" >/dev/null 2>&1
    fi
    if [[ ! -f "$KEYCHAIN" || ! -s "$PASSWORD_FILE" ]]; then
        echo "Incomplete signing identity in $SIGNING_DIR. Restore it from backup; refusing to replace it." >&2
        exit 1
    fi
    PASSWORD=$(cat "$PASSWORD_FILE")
    security unlock-keychain -p "$PASSWORD" "$KEYCHAIN"
    IDENTITY=$(security find-certificate -c 'Volta Local Signing' -p "$KEYCHAIN" | openssl x509 -noout -fingerprint -sha1 | sed 's/.*=//; s/://g')
    [[ -n "$IDENTITY" ]] || { echo 'Local signing certificate missing.' >&2; exit 1; }
    codesign --force --sign "$IDENTITY" --keychain "$KEYCHAIN" --identifier local.volta.engine "$APP/Contents/Helpers/spacekeeper"
    codesign --force --sign "$IDENTITY" --keychain "$KEYCHAIN" --identifier local.volta.app "$APP"
fi
codesign --verify --deep --strict "$APP"
