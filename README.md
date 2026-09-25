<p align="center"><img src="images/icon.png" width="128" alt="Magpie icon"></p>

# Magpie

A fast, keyboard-first clipboard manager for macOS. Magpie keeps everything you copy (text, links, images, files and colours) and gets any of it back in a couple of keystrokes.

<p align="center"><img src="images/panel.png" width="720" alt="Magpie's history panel in light and dark mode"></p>

## Features

- **Native on Apple silicon**, with a Liquid Glass panel that slides in from any screen edge or floats in the centre
- **Pinned items** that are never trimmed from history and survive Clear History (⌘P)
- **Filters** for pinned items, text, links, images, files and colours (⌘← / ⌘→)
- **Ranked search** across text, file names, the app something was copied from, and **text inside images**, recognised on-device with Vision
- **Source app and time** shown on every item
- **Paste as plain text** (⌥↩). For images, this pastes the recognised text
- **Excluded apps**: nothing copied from them is saved. Password managers are excluded by default, and anything an app marks as a password or temporary is never saved
- **Right-click actions**: paste, paste as plain text, pin, preview, copy recognised text, open link, show in Finder, delete

## Keyboard shortcuts

| Action | Shortcut |
| --- | --- |
| Show / hide Magpie | ⇧⌘V (configurable) |
| Paste selected item | ↩ |
| Paste as plain text | ⌥↩ |
| Paste item 0–9 | ⌘0 – ⌘9 |
| Pin / unpin | ⌘P |
| Previous / next filter | ⌘← / ⌘→ |
| Search | ⌘\\ |
| Preview | ⌃Space |
| Delete | ⌃⌫ |
| Move panel | ⌃⌥⌘ + arrow |

## Requirements

- macOS 26 or later
- Accessibility access, which Magpie needs in order to paste into other apps

## Building

1. Install [Xcode](https://developer.apple.com/xcode/) and [CocoaPods](https://cocoapods.org) (`brew install cocoapods`).
2. Run `pod install`.
3. Open `Yippy.xcworkspace` and run the **Yippy** scheme.

The Xcode project, targets and some class names still use the original Yippy naming. They'll be renamed during the upcoming architecture update.

### Build configurations

- **Release / Debug**: the app (`com.sandcheeeez.Magpie`)
- **Beta Release / Beta Debug**: a beta build with its own bundle id, orange icon and data
- **XCTest**: tests and development tooling, with its own bundle id so they never touch your real history

To render the UI with sample data into PNGs without touching your real history, run the XCTest build with `--snapshot=<output dir>`.

### Regenerating the icon

The app icon is drawn in code: `swift tools/make-icon.swift Yippy/Resources/Assets.xcassets/AppIcon.appiconset` (add `beta` for the beta icon).

## Roadmap

- [ ] Replace RxSwift with Swift Observation and async/await
- [ ] Move history storage to SwiftData
- [ ] iCloud sync of history and pins
- [ ] Rename the Xcode project and types from Yippy to Magpie
- [ ] Signed and notarised releases

## Credits

Magpie is a fork of [Yippy](https://github.com/mattDavo/Yippy) by Matthew Davidson, used under the MIT License. See [LICENSE](LICENSE).
