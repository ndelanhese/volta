#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
SOURCE="$PWD"
APP="$SOURCE/dist/Volta.app"
./test.sh
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Helpers" "$APP/Contents/Resources"
(
    cd Engine
    go build -trimpath -ldflags='-s -w' -o "$APP/Contents/Helpers/spacekeeper" ./cmd/spacekeeper
)
swiftc -swift-version 6 -O Lifecycle.swift Volta.swift \
    -o "$APP/Contents/MacOS/Volta" \
    -framework AppKit -framework SwiftUI -framework ApplicationServices -framework ServiceManagement
cp Info.plist "$APP/Contents/Info.plist"
cp Engine/LICENSE "$APP/Contents/Resources/spacekit-LICENSE.txt"
cp LICENSE "$APP/Contents/Resources/LICENSE.txt"
cp THIRD-PARTY-LICENSES.txt "$APP/Contents/Resources/THIRD-PARTY-LICENSES.txt"
cp THIRD-PARTY.md "$APP/Contents/Resources/THIRD-PARTY.md"
codesign --force --sign - --identifier local.volta.engine "$APP/Contents/Helpers/spacekeeper"
codesign --force --sign - --identifier local.volta.app "$APP"
codesign --verify --deep --strict "$APP"
printf 'Built and verified: %s\n' "$APP"
