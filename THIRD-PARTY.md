# Third-party code

Volta embeds a locally compiled, modified spacekeeper from [cehbz/spacekit](https://github.com/cehbz/spacekit),
MIT, Copyright (c) 2026 Charles Haynes. Base commit: `5363f0b8285832e505fd030aa1199113f3b83981`.
Full source and license are in `Engine/`.

Local modifications: isolated data directory; manual remember command; parent-process lifetime;
recreation of missing desktops after display reconnection; desktop deficit calculation based on
positions so historical UUIDs do not create surplus desktops.

Go dependency versions and transitive dependencies are pinned in `Engine/go.mod` and `Engine/go.sum`.
Their license notices, plus the Go runtime license, are collected in `THIRD-PARTY-LICENSES.txt`
and included in the app bundle.
REA 6.7.0 was installed separately as a development inspection tool; Volta does not need Node,
REA, a disassembler, a cloud service, or a subscription at runtime.
