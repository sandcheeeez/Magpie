# Magpie

macOS 26 clipboard manager (fork of mattDavo/Yippy, MIT). Swift: AppKit panel, SwiftUI settings, SwiftData storage, Observation. The only dependency is HotKey (SPM). Repo: github.com/sandcheeeez/Magpie, default branch `main`.

Read `docs/ARCHITECTURE_PLAN.md` for design decisions and remaining work. Update its checklists as you finish items.

## Commands

All of these print only errors and results. Use them instead of raw `xcodebuild`, whose output is huge.

- `scripts/build`: quick unsigned Release build
- `scripts/test`: unit tests (`MagpieTests`), with a 5-minute limit
- `scripts/install`: signed build installed to /Applications/Magpie.app and relaunched. Signing uses team 8ML4S57F6X, so Accessibility permission survives.
- `scripts/snapshot <dir>`: renders the panel and settings to PNGs with sample data (XCTest build, isolated data). Use it to check UI changes visually; screen capture isn't available.
- `scripts/xcodeproj add|remove|rename …`: adds new files to the Xcode project (`TARGET=MagpieTests` for test files). New `.swift` files must be added this way or they won't compile.

## Rules

- **History stays local.** Never add networking (URLSession, WebKit, Network, sockets, remote HTML). `PrivacyTests` enforces this. iCloud, if added, must use only the user's own account.
- **Never touch real user data in tests or tools.** The XCTest configuration has its own bundle id (`com.sandcheeeez.MagpieXCTest`); `--uitesting` and `--snapshot` only work there.
- **UI tests take over the mouse and keyboard.** Only run them when the owner says it's a good time, and quit the installed Magpie first (both claim ⇧⌘V).
- **Commits:** author `sandcheeeez <65209530+sandcheeeez@users.noreply.github.com>`, end messages with the Claude co-author line, push to `origin main`. `upstream` is mattDavo/Yippy; the `apple-silicon-universal` branch backs the open PR there, so leave it alone.
- **Code style:** match the surrounding code. AppKit classes must call the global observation helper as `Magpie.observe(...)`, because `NSObject.observe` shadows it.
- **Regex patterns** in `ClipAnalyzer` must avoid nested quantifiers (e.g. `(\s*x+)*`); one caused catastrophic backtracking that hung the tests.
- **Bundle id** stays `com.sandcheeeez.Magpie` until the first public release (see the plan's release checklist).

## Layout

- `Magpie/Sources/Models`: `AppState`, `History` (+ `ClipModels`, `ClipAnalyzer`, `HistoryItem`), search, settings, `MCP/MCPServer`
- `Magpie/Sources/Windows`: `Panel/` (history panel), `Settings/` (SwiftUI), preview, about, help
- `MagpieTests`: Swift Testing suites (in-memory SwiftData); `MagpieUITests`: UI tests
- `tools/`: icon generator, screenshot cropper
