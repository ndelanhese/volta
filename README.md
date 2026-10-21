# Volta

**Unplug your displays. Plug them back in. Put your workspace back.**

[![Tests](https://github.com/ndelanhese/volta/actions/workflows/tests.yml/badge.svg)](https://github.com/ndelanhese/volta/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS-black.svg)](#requirements)

Volta is a free, local macOS menu bar app that remembers window positions, sizes,
and Mission Control desktop assignments for each set of connected displays.
It restores the corresponding arrangement when you dock or undock your Mac.

No account, subscription, cloud service, or runtime AI dependency. Available in **English and Brazilian Portuguese**.
The interface follows your macOS language by default; the in-app **Language** selector switches immediately
and remembers your choice. Unsupported system languages fall back to English.

[Leia em português](LEIA-ME.md) · [Download preview](https://github.com/ndelanhese/volta/releases) · [Report a bug](https://github.com/ndelanhese/volta/issues/new?template=bug_report.yml)

## What it does

- Keeps separate arrangements for your laptop and external-display setups.
- Remembers which regular Mission Control desktop each window belongs to.
- Learns deliberate changes on visible desktops every five seconds.
- Waits ten seconds after the last display change before restoring, allowing macOS to settle.
- Stages windows from hidden desktops when needed to restore their dimensions.
- Recreates missing regular desktops after reconnection, without duplicating historical UUIDs.
- Provides **Remember now**, **Restore arrangement**, pause,
  local recovery snapshots, a history log, and optional launch at login.

Volta uses a native Swift/AppKit/SwiftUI interface and embeds a modified
[spacekeeper engine from spacekit](https://github.com/cehbz/spacekit). It does not require disabling SIP.

## Requirements

The downloadable preview is **Apple Silicon / macOS 27+**, tested on macOS 27.0.1.
Other macOS versions and Intel Macs have not been validated. Some engine operations rely on private
SkyLight APIs introduced in macOS 26.4; future macOS releases may change them.

To build from source, install Swift 6 or newer via Xcode Command Line Tools and Go 1.26 or newer.
The current release was built with Swift 6.4 and Go 1.26.0. A paid Apple Developer account is not needed.

## Install and set up

1. Download the Apple Silicon ZIP from [Releases](https://github.com/ndelanhese/volta/releases).
2. Extract it, move **Volta.app** to **Applications**, and open it.
3. Grant **Accessibility** in System Settings → Privacy & Security. Volta needs it to move and resize windows.
4. Optionally grant **Screen Recording** to identify window titles across hidden desktops. Volta does not record images or audio.
5. With your external displays connected, arrange your windows and desktops, then click **Remember now**.
6. Disconnect your displays, arrange the laptop layout once, and click **Remember now** again.

Subsequent display changes restore the arrangement for that display set. Wait about ten seconds after
the last display change. When rearranging manually, allow five seconds for learning before unplugging,
or click **Remember now** explicitly.

The menu bar icon opens the controls. The `…` menu contains optional launch at login and quit.
Closing the controls leaves Volta running; quitting stops its helper.

The **Language** selector offers **Follow macOS**, **English**, and **Português (Brasil)**. Buttons,
menus, accessibility labels, display counts, and existing status/error messages update without restarting.
macOS permission dialogs follow macOS language settings; their descriptions are localized too.
Technical engine logs remain in English, and error details supplied by macOS follow the OS language.
See [Localization](docs/LOCALIZATION.md) to add translations.

### Preview signing and permissions

Starting with beta.3, preview downloads use a persistent, self-signed certificate. They are **not
notarized by Apple**. macOS may require approval under System Settings → Privacy & Security before
opening a downloaded build. See [Apple's guidance for safely opening apps](https://support.apple.com/en-us/102445).

Earlier previews used ad hoc signatures tied to each executable's code hash. Updating could invalidate
Accessibility and Screen Recording grants. The new signing identity remains the same across rebuilds.
Migrating from an earlier preview, or switching between a downloaded app and your own build, requires
one new authorization. Remove the old Volta entry and add `/Applications/Volta.app` if necessary.
Permissions belong to macOS; Volta checks them directly and cannot grant itself access.

Source builds create a free local signing identity once, in
`~/Library/Application Support/Volta/Signing/`. Keep this directory private and preserve it when
updating or moving the source checkout: it contains the signing keychain and its password, with
owner-only permissions. It is not included in the app or committed to Git. The self-signed certificate
is valid for ten years and is used only for code signing; no system trust settings are changed.
Back up this directory securely. Losing it means creating a new identity and authorizing again.
See [Apple's explanation of stable signing requirements](https://developer.apple.com/library/archive/technotes/tn2206/).

`VOLTA_SIGNING_DIR=/absolute/private/path ./build.sh` overrides the identity location.
`VOLTA_ADHOC=1 ./build.sh` explicitly opts into disposable signing for test artifacts; grants may
be lost on every changed build. Normal builds fail if the saved identity is incomplete rather than
silently replacing it.

## Build and test

```bash
git clone https://github.com/ndelanhese/volta.git
cd volta
./test.sh
./build.sh
open dist/Volta.app
```

`build.sh` runs the tests, compiles both executables, assembles `dist/Volta.app`, signs it locally,
and verifies the bundle signature. Xcode's full IDE is not required.
The app is standalone after compilation; users do not need Go, Node.js, REA, or a decompiler.

GitHub Actions runs the Go, Swift, localization, and signing identity checks. Native display/Space integration requires
an interactive Mac and is documented separately in [Testing](docs/TESTING.md).

## Local data

Volta stores its data in `~/Library/Application Support/Volta/`:

| File | Purpose |
| --- | --- |
| `spacekeeper.db` | Per-display arrangements and placement history |
| `snapshots/` | Local recovery points |
| `watch.log` | Monitoring and restoration results |
| `last-command.log` | Result of the last manual operation |
| `status.json` | Permissions and helper status, without window titles |

History may contain app names and window titles. It stays on your Mac. Remove personal details before
attaching logs to a public issue. The app does not send telemetry or screenshots.

## Current limits

- The automatic arrangement model targets **regular Mission Control desktops**.
  Native fullscreen, Split View pairs, and windows assigned to all desktops are not reconstructed equivalently.
- Some apps refuse Accessibility movement or resizing. Check **History** for failed repairs.
- The first visit to a new display configuration needs an initial arrangement.
- Recreating missing desktops briefly opens Mission Control. Volta does not delete desktops.
- Restoring an assignment does not reopen closed apps or recover documents.
- Closed/recreated windows are matched by app, title, and geometry; ambiguous matches can fail.
- Private macOS APIs can change. This is an experimental public preview, not a guarantee for every app or display setup.

## Project layout

```text
Volta.swift        Native controls, permissions, and helper supervision
Lifecycle.swift   Helper start/stop policy
Localization.swift Language selection, formatting, and English fallback
Resources/        Native en.lproj and pt-BR.lproj string tables
Tests.swift       Lifecycle checks
Engine/           Vendored, modified MIT spacekit engine and tests
test.sh           Local and CI test entry point
build.sh          Standalone app build and local signing
docs/TESTING.md   Verification scope and native test procedure
```

Contributions are welcome: see [CONTRIBUTING.md](CONTRIBUTING.md).
Changes are recorded in [CHANGELOG.md](CHANGELOG.md).

## Credits and license

MIT © 2026 Nathan Delanhese. The embedded engine is based on
[cehbz/spacekit](https://github.com/cehbz/spacekit), MIT © 2026 Charles Haynes.
Its original license is preserved in [Engine/LICENSE](Engine/LICENSE).
See [THIRD-PARTY.md](THIRD-PARTY.md) for the upstream commit and local changes.
