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
- [ ] Add `AppState` (`@Observable`) and `Settings` persistence without `Default`
- [ ] Move `Controller` (status menu), `YippyWindowController`, the preview window, the filter chips and `YippyViewController` onto `AppState`
- [ ] Move `SettingsModel` (SwiftUI settings) onto `AppState`
- [ ] Delete the unused storyboard settings screens (`GeneralSettingsViewController`, `HotKeySettingsViewController`, `SettingsTabViewController`) and their scenes
- [ ] Remove the RxSwift, RxCocoa and Default pods, CocoaPods itself, and the unused fuse-swift package. The project then opens as a plain `.xcodeproj`

### Phase 2: SwiftData storage
- [ ] Add the `ClipItem` and `ClipRepresentation` models and a `HistoryStore` (the `ModelContainer`)
- [ ] Make `HistoryItem` wrap `ClipItem`, and rewrite `History` on the store (insert, delete, move, pin, trim, clear, recognised text)
- [ ] Delete the old file-based storage and its metadata store
- [ ] Update the snapshot tool

### Phase 3: Tests
- [ ] Replace the outdated tests (Rx and file-storage based, and currently not compiling) with Swift Testing tests: history operations against an in-memory store, search ranking, settings decoding, filters

### Phase 4: Naming
- [ ] Rename the internal `Yippy*` types, files, targets, schemes and project to Magpie

## Notes

- Existing history does not need migrating (owner's decision, 2026-09-25). The first SwiftData launch starts empty.
- `--snapshot=<dir>` (XCTest configuration only) renders the UI with sample data. Use it to check visual changes.
