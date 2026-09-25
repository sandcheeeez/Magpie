# Architecture update plan

Goal: remove RxSwift and CocoaPods, move history storage to SwiftData, and leave the codebase in one consistent modern Swift style (Observation, async/await), with working tests.

Work happens on `main` in small commits. Each checked step has been built and committed. If work is interrupted, resume at the first unchecked step.

## Design

- **App state.** `State` (Rx relays) becomes an `@Observable @MainActor` class. AppKit code reacts to changes with `Observations { ... }` async sequences (Swift 6.2, macOS 26), consumed in tasks.
- **Settings.** The `Default` pod is replaced with a small `UserDefaults` + `Codable` store. `Settings` keeps decoding older saved versions.
- **History events.** `History` keeps its explicit change callbacks (`insert`, `delete`, `move`, ...). The table view needs to know *what* changed to keep the selection stable, and these are plain closures, not Rx.
- **Storage.** SwiftData models:
  - `ClipItem`: id, position (ordering), copiedAt, source app, pinned, recognised text, kind, folded search text
  - `ClipRepresentation`: pasteboard type plus data, with `.externalStorage` so large images live outside the database

  They replace `HistoryFileManager`, `HistoryCache`, `ArrayFileManager`, `DataFileManager` and `HistoryMetadataStore`. `HistoryItem` stays the `NSObject` the UI and pasteboard use (it must conform to `NSPasteboardWriting`), and wraps a `ClipItem`.
- **Ordering.** Each item has a `Double` position. New or pasted items go on top (max + 1), and dragging an item places it at the midpoint of its neighbours.
- **Panel UI.** It stays AppKit (`NSTableView`) for now. It is fast, and the global hotkey handling is built around it.

## Steps

### Phase 0: Signing
- [x] Sign builds with the owner's Apple Development certificate (team 8ML4S57F6X), so Accessibility permission survives rebuilds

### Phase 1: Remove RxSwift and CocoaPods
- [x] Add `AppState` (`@Observable`) and `Settings` persistence without `Default`
- [x] Move `Controller` (status menu), `YippyWindowController`, the preview window, the filter chips and `YippyViewController` onto `AppState`
- [x] Move `SettingsModel` (SwiftUI settings) onto `AppState`
- [x] Delete the unused storyboard settings screens (`GeneralSettingsViewController`, `HotKeySettingsViewController`, `SettingsTabViewController`) and their scenes
- [x] Remove the RxSwift, RxCocoa and Default pods, CocoaPods itself, and the unused fuse-swift package. The project then opens as a plain `.xcodeproj`

### Phase 2: SwiftData storage
- [x] Add the `ClipItem` and `ClipRepresentation` models and a `HistoryStore` (the `ModelContainer`)
- [x] Make `HistoryItem` wrap `ClipItem`, and rewrite `History` on the store (insert, delete, move, pin, trim, clear, recognised text)
- [x] Delete the old file-based storage and its metadata store
- [x] Update the snapshot tool

### Phase 3: Tests
- [x] Replace the outdated tests (Rx and file-storage based, and currently not compiling) with Swift Testing tests: history operations against an in-memory store, search ranking, settings decoding, filters
- [ ] Run the UI tests on a machine where it's fine for them to take over the mouse and keyboard, and fix any failures

### Phase 4: Naming
- [x] Rename the internal `Yippy*` types, files, targets, schemes and project to Magpie

## Notes

- AppKit classes inherit `NSObject.observe` (KVO), so they call the global helper as `Magpie.observe`.
- Observation delivers changes asynchronously, so code that must run straight after a state change (e.g. the panel frame in `show()`) reads the state directly rather than waiting for an observer.

- `HistoryItem` copies the model's small fields and sets `isRemoved` before its model is deleted. Reading a deleted SwiftData model crashes, and the UI can briefly hold removed items.
- Existing history does not need migrating (owner's decision, 2026-09-25). The first SwiftData launch starts empty.
- `--snapshot=<dir>` (XCTest configuration only) renders the UI with sample data. Use it to check visual changes.

### Phase 5: Features requested 2026-09-25
- [x] **Content analysis.** A single `ClipAnalyzer` works out kind, tags and stats when an item is copied. Kinds gain `code`, and text such as `#598CF2` / `rgb(…)` / `hsl(…)` counts as a colour. Tags cover the code language, email, phone, address and date. Stored items are re-analysed whenever the analyser version increases.
- [x] **Footer details.** Character count for text, and the language for code.
- [x] **Filters.** A Code chip, plus a Tags menu listing the tags present in the history.
- [x] **Unlimited history.** Add an "Unlimited" option to the history size.
- [x] **Storage settings.** Show total size, a breakdown by kind, and the largest items with delete buttons, plus bulk clearing per kind. Pinned items are protected.
- [x] **Privacy.** Remove the unused WebKit-backed HTML parsing and the old website link. Add a test that fails if network APIs appear in the app. Document the local-only guarantee.
- [x] **MCP server.** `Magpie --mcp` speaks MCP over stdio and reads the history store read-only. It is off until enabled in Settings, runs locally only, and only returns what Magpie already stored (excluded and concealed items never exist).
- [x] **UI tests.** Update `MagpieUITests` for the current UI: fixtures built in code, and new search, filter and pin tests. They compile but haven't been run yet. They take over the mouse and keyboard, and need the test runner to be allowed to control the computer.

## Before the first public release
- [ ] Switch the bundle id from `com.sandcheeeez.Magpie` to one based on the owner's domain (`com.<domain>.Magpie`), before anyone else installs it. Changing it later resets every user's history, settings and Accessibility permission.
- [ ] Sign with a Developer ID certificate and notarise. The Apple Development certificate used for local builds embeds the owner's Apple ID email, so share source rather than builds until then.
