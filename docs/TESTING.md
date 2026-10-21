# Testing

## Automated checks

Run `./test.sh`. It executes the complete Go suite and six Swift lifecycle assertions covering
start, permission denial/revocation, pause, and duplicate-process prevention.

The initial public preview passed 85 Go test functions on macOS 27.0.1 / Apple Silicon.
Added regressions cover manual adoption of hidden-window intent and clearing pending repairs,
data-directory isolation, and repeated historical Space UUID generations not creating surplus desktops.

`./build.sh` also compiles the app and verifies its persistent local certificate signature.
Signing regression checks compile two different executable versions and require identical app/helper
designated requirements, different code hashes, and a certificate-bound identity. A missing identity
password must fail without regenerating a certificate. Test identities use temporary keychains and
are removed afterward. These checks prove signing stability, not an actual macOS permission grant.
GitHub Actions exercises the noninteractive tests; it does not grant macOS privacy permissions.

Localization checks also exercise system-language negotiation, explicit language overrides, English
fallback for a missing key, zero/one/many display counts, retranslation of an existing status message,
and matching keys/placeholders across all 40 English and Portuguese UI translations.

## Native verification performed

On macOS 27.0.1, a disposable resizable AppKit window was moved between two existing regular desktops
and returned, with membership verified through WindowServer. A snapshot containing only that window
was then restored using the actual helper: desktop, position, and dimensions all matched.

This proves the native primitives for that test window. It does not prove every application's
behavior or every physical dock/display combination.

For beta.2, the installed app was exercised through native Accessibility: switching English ↔ pt-BR
updated real control labels, the already-visible status message, and the menu bar accessibility label.
The Portuguese selection survived quitting and reopening. The selector was then returned to Follow macOS.
The same localization checks passed against resources inside the compiled app bundle.

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
9. Switch English ↔ Portuguese and check controls, existing status/error messages, the menu icon,
   display plurals, and window sizing. Reopen the app and verify the selected language persists.

Record OS version, Mac architecture, number of displays, connection/dock type, affected apps,
whether native fullscreen/Split View was involved, and any sanitized failure messages.
Do not present a passing unit suite as proof of physical hotplug fidelity.

10. With permissions granted, quit/reopen the installed app twice and verify both permissions remain.
    Rebuild with the same signing directory, quit, replace the installed app, reopen, and check again.
