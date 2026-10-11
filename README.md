# Clippy

A fast, keyboard-driven clipboard history manager for macOS, in the spirit of
[Maccy](https://github.com/p0deje/Maccy), built for the Mac App Store.

> Before you submit, check that "Clippy" is available in App Store Connect
> and read the naming note in [docs/APP_STORE.md](docs/APP_STORE.md): the
> name is closely associated with Microsoft's Office assistant.

## Features

- Lives in the menu bar, with no Dock icon
- **⇧⌘C** (configurable) opens a searchable history at the mouse pointer
- Keeps text, rich text, images and files, and restores every format exactly
- Fuzzy search: `gtco` finds `git commit`
- Keyboard first: ↑/↓, ⏎ paste, ⌥⏎ paste as plain text, ⌘1–⌘9, ⌘P pin, ⌘⌫ delete, Esc
- Pinned items stay at the top and never expire
- Optional auto-paste into the app you were using (needs Accessibility access)
- Ignores password managers and anything marked concealed or transient
  ([nspasteboard.org](http://nspasteboard.org) conventions)
- You can pause recording, block extra apps, and set the history size
- A first-launch welcome window covering the menu bar icon, the shortcut,
  auto-paste, and launch at login
- Launch at login, off by default as App Store rules require
- History is stored locally with SwiftData. There is no network access and
  no analytics.

## Requirements

- macOS 14 Sonoma or later
- Xcode 16 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build and run

```sh
xcodegen          # generates Clippy.xcodeproj from project.yml
open Clippy.xcodeproj
```

In Xcode, select the **Clippy** target, open **Signing & Capabilities**,
choose your team, then press ⌘R. A clipboard icon appears in the menu bar.

The `.xcodeproj` is generated and git-ignored, so change `project.yml` and
re-run `xcodegen` rather than editing project settings in Xcode.

## Project layout

```
project.yml                  XcodeGen spec (targets, sandbox entitlement, Info.plist)
ClipCore/                    Swift package with no AppKit dependency, tested on Linux and macOS
  Sources/ClipCore/
    PasteboardEntry.swift    Stored representation of a copy and its kind (text/image/file)
    CaptureRules.swift       What to ignore: password managers, concealed types, size limit
    ContentFingerprint.swift Dedupe key, so the same text from two apps makes one row
    FuzzyMatcher.swift       Search ranking
    HistoryRules.swift       History trimming and row titles
App/Sources/
  ClippyApp.swift            Entry point
  AppDelegate.swift          Menu bar item, hotkey, settings window
  Models/                    SwiftData model and preferences
  Services/                  Pasteboard polling, storage, paste, launch at login
  Popup/                     Floating search panel and list UI
  Settings/                  Settings and first-launch welcome windows
App/Resources/               Asset catalog (app icon) and privacy manifest
scripts/make_icon.py         Draws the placeholder icon at every size
docs/APP_STORE.md            Submission checklist
```

## Tests

```sh
cd ClipCore && swift test
```

CI (`.github/workflows/ci.yml`) runs these tests on Linux and builds the full
app on a macOS runner.

## How it works

- **Capture**: macOS has no clipboard-changed event, so `ClipboardMonitor`
  polls `NSPasteboard.changeCount` every 0.5 s and reads data only when the
  count changes.
- **Popup**: `PopupPanel` is a *non-activating* `NSPanel`. It takes keyboard
  focus for the search field, but the app you were typing in stays active,
  so the paste goes there.
- **Auto-paste**: after putting the item on the pasteboard, the app posts a
  synthetic ⌘V. macOS only allows that once the user grants Accessibility
  access, so the feature is off until enabled in Settings.

## To do before release

- [ ] Final app icon. The current one is a placeholder drawn by
      `scripts/make_icon.py` (edit it and re-run, or drop in designed PNGs).
- [ ] Final name and bundle ID (`project.yml`: `PRODUCT_BUNDLE_IDENTIFIER`)
- [ ] Manual QA pass on macOS 14, 15 and the current release, especially
      the arrow keys and ⏎ in the search field, and auto-paste in a few apps
      (Safari, Notes, VS Code, Terminal, Slack)
