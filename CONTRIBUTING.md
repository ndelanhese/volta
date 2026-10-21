# Contributing

Keep Volta free, local, and small. Preserve upstream attribution in `Engine/`.

1. Open an issue for behavior changes or substantial work.
2. Make a focused branch and include a regression test for nontrivial logic changes.
3. Run `./test.sh`; run `./build.sh` on a Mac before submitting UI or native integration changes.
4. Describe what changed, why, how it was tested, and which macOS/display configurations were exercised.

Go changes should be formatted with `gofmt`. Swift code is compiled in Swift 6 mode.
CI checks domain logic; it cannot prove real display reconnection or TCC permissions.
Do not disable SIP or globally weaken macOS security to make tests pass.

Native testing should use disposable windows. Avoid moving another person's work as a side effect.
Never commit window snapshots, local databases, signing keys, certificates with private keys, or personal logs.
See [docs/TESTING.md](docs/TESTING.md) for the manual matrix.
