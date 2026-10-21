# Testing

## Automated checks

Run `./test.sh`. It executes the complete Go suite and six Swift lifecycle assertions covering
start, permission denial/revocation, pause, and duplicate-process prevention.

The initial public preview passed 85 Go test functions on macOS 27.0.1 / Apple Silicon.
Added regressions cover manual adoption of hidden-window intent and clearing pending repairs,
data-directory isolation, and repeated historical Space UUID generations not creating surplus desktops.

`./build.sh` also compiles the app and verifies its ad hoc code signature.
GitHub Actions exercises the noninteractive tests; it does not grant macOS privacy permissions.

## Native verification performed

On macOS 27.0.1, a disposable resizable AppKit window was moved between two existing regular desktops
and returned, with membership verified through WindowServer. A snapshot containing only that window
was then restored using the actual helper: desktop, position, and dimensions all matched.

This proves the native primitives for that test window. It does not prove every application's
behavior or every physical dock/display combination.

## Manual acceptance matrix

Use disposable windows and save useful work before exercising display changes.

1. Connect the desired displays, arrange windows across regular desktops, and click **Memorizar agora**.
2. Disconnect external displays. After stabilization, arrange the laptop-only configuration and remember it.
3. Reconnect and wait at least ten seconds after the last display event. Check desktop assignments and frames.
4. Repeat at least twice, verifying no extra desktops accumulate.
5. Change a window on a visible desktop, wait five seconds, and repeat the display cycle.
6. Test sleep/wake, reopening controls, pause/resume, and optional launch at login.
7. Revoke Accessibility; the helper should stop. Re-grant it; the helper should start once.
8. Quit the app; its helper should exit. An unexpected parent exit is detected on the next polling interval.

Record OS version, Mac architecture, number of displays, connection/dock type, affected apps,
whether native fullscreen/Split View was involved, and any sanitized failure messages.
Do not present a passing unit suite as proof of physical hotplug fidelity.
