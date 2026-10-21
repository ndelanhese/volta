#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/volta-tests.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT
swiftc -swift-version 6 -O Lifecycle.swift Localization.swift LocalizationTests.swift Tests.swift -o "$TEST_DIR/lifecycle-tests"
"$TEST_DIR/lifecycle-tests" "$PWD/Resources"
(
    cd Engine
    go test ./...
)
