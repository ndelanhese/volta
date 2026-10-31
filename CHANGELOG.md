# Changelog

## 1.0.0 — 2026-10-31

- Learn window movements automatically without restoring them during normal use.
- Restore only after a connected display is added or removed and the display set changes; skip startup restoration and transient wake reconfigurations.
- Keep hidden window geometry protected and remove the manual restore button.

## 1.0.0-beta.6 — 2026-10-25

- Prevent spontaneous window staging/resizing from compositor frame offsets on hidden desktops.
- Separate currently visible desktops from previously visible ones when learning window frames.
- Hold observations and snapshots during the desktop-change quiet period.
- Reject native geometry while WindowServer reports a desktop animation, including a held swipe.
- Keep trusted hidden frames in snapshots; defer unknown hidden geometry until its desktop is shown.
- Preserve explicit restoration after display reconnection and application relaunch.

## 1.0.0-beta.5 — 2026-10-20

- Compact native plist transport for window, desktop, and title observations; no polling or settling delays changed.
- Avoid SwiftUI redraws when observed values are unchanged.
- Refresh launch-at-login status when opening or activating controls, instead of polling the system service.
- Native bridge regression coverage for Unicode titles, exact desktop IDs, fractional frames, and payload size.

## 1.0.0-beta.4 — 2026-10-20

- Native application icon with full standard and Retina sizes.
- Build bundles now live in a `.noindex` directory to keep disposable copies out of Spotlight.

## 1.0.0-beta.3 — 2026-10-20

- Persistent local certificate signing for app and helper, replacing code-hash-bound ad hoc identities.
- Rebuilds reuse the saved private identity; incomplete identities fail rather than silently resetting grants.
- Signing regression checks compare different executables and verify stable certificate requirements.
- One-time permission migration is required when replacing the previous ad hoc previews.

## 1.0.0-beta.2 — 2026-10-20

- English and Brazilian Portuguese localization through native `.lproj` resources.
- Automatic macOS language detection, English fallback, and a persistent in-app language selector.
- Immediate translation of controls, menus, accessibility labels, and existing status/error messages.
- Localized display-count plurals and system permission descriptions.
- Localization checks covering language negotiation, overrides, fallback, placeholders, and all UI keys.

## 1.0.0-beta.1 — 2026-10-20

Initial public preview.

- Native macOS menu bar controls for a bundled, locally compiled spacekeeper engine.
- Separate learned arrangements per set of connected displays.
- Explicit memorization and automatic staged restoration of regular desktop assignments and frames.
- Accessibility onboarding, optional window-title permission, pause, logs, and optional launch at login.
- Isolated Application Support data and parent-process supervision for the helper.
- Missing-desktop recreation after reconnecting displays.
- Regression fix: historical Space UUIDs no longer inflate the number of desktops to recreate.
- Go regression tests, Swift lifecycle checks, and a GitHub Actions test workflow.

Preview binary: Apple Silicon, tested on macOS 27.0.1. Ad hoc signed; not notarized.
