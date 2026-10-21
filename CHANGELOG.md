# Changelog

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
