# Changelog

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
