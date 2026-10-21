# Performance verification

## Changes in beta.5

Idle profiles showed repeated XML serialization at the native C/Go boundary, followed by XML parsing,
and SwiftUI view work caused by assigning unchanged published values. The interface also queried
`SMAppService` status every two seconds.

Window, desktop, and title observations now use CoreFoundation binary property lists across the same
boundary. The existing typed plist decoder still reads every field. The interface only publishes changed
permission/display values; launch-at-login status refreshes when controls open or the app activates.

The five-second learning interval, 400 ms two-sample movement check, ten-second display settling
period, Space notifications, snapshot cadence, and restoration algorithm were not changed.
Permissions are still checked every two seconds.

## Native bridge checks

The regression fixture uses the same native producer as the real bridge. It checks compact payload
size (22,195 bytes versus 118,906 bytes with XML) and preserves 200 windows, Unicode titles, fractional/negative frames, exact 64-bit desktop IDs,
ordered desktops on two displays, space membership, and empty titles/lists. It failed against the previous XML transport and passes
with the compact transport.

Run the bridge benchmark:

```bash
cd Engine
go test ./internal/skylight -run TestNativeBridge -bench BenchmarkNativeBridgeDecode -benchmem
```

On Apple M1 Pro, macOS 27.0.1, decoding the fixture took approximately 0.484 ms with binary plist
versus 3.605 ms with XML (7.5× faster). Allocations fell from about 2.03 MB / 58,735 allocations to
0.44 MB / 9,556 allocations per decode. This is a transport benchmark, not whole-app CPU usage.

## Whole-app CPU sample

On the same Apple M1 Pro / macOS 27.0.1 session, with one connected display and the watcher enabled,
CPU time was sampled over 60 seconds before and after installing beta.5. The optimized process was
allowed to finish startup before sampling. Percentages are relative to one CPU core; they are derived
from the change in cumulative process CPU time divided by elapsed wall time.

| Process | Before | After |
| --- | ---: | ---: |
| Volta interface | 0.599% | 0.067% |
| spacekeeper engine | 2.131% | 0.966% |
| Total | 2.730% | 1.033% |

This sample used approximately 62% less CPU. It is an idle-session comparison on one Mac, not a
promise for every workload or a measurement of display-reconnection peaks. Memory was not the
optimization target; fresh-process resident memory and compressed-memory state are not directly
comparable to the older process in this run.

## Functional verification

The installed helper restored a disposable resizable window from another regular desktop: desktop,
position, and dimensions matched. Movement to another existing desktop and back also passed.
The signed update retained both Accessibility and Screen Recording authorization. Two further
quit/reopen cycles retained both permissions and restarted the helper. English ↔ Portuguese and
Follow macOS controls also passed a native UI check.

Physical disconnect/reconnect tests with two external monitors were not performed in this run.
