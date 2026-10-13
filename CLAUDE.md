# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

Built via GitHub Actions on push to main (`.github/workflows/build.yml`, macos-14, Xcode 15.2). Download the artifact from the Actions tab, or run `scripts/install-latest.sh`, which downloads it, re-signs it with the local certificate (`scripts/create-signing-cert.sh`, run once) and installs it to /Applications.

There is no local Xcode on the dev machine. To type-check before pushing:

```
swiftc -typecheck -target arm64-apple-macos14.0 -sdk "$(xcrun --show-sdk-path)" Shoshin/*.swift
```

## Architecture

Shoshin is a menu bar app (`LSUIElement`) holding a growing list of small mindfulness and focus tools. A `.window`-style `MenuBarExtra` shows an accordion: one row per tool; choosing a row collapses the others and opens the tool in place. The choice persists in `@AppStorage("selectedTool")`, so the panel reopens on the same tool. The chosen row's chevron (or "‹ All tools" in the footer) returns to the list.

- `ShoshinApp.swift`: `@main`, `MenuBarLabel` (enso glyph, plus the focus countdown while a block runs), `ToolPanel` (the accordion), `ToolRow`.
- `ToolRegistry.swift`: the `ShoshinTool` protocol and `ToolRegistry.all`, the panel order.
- `BreathingTool.swift`: box breathing, 4 s per phase, drawn as a wave in a `Canvas` driven by `TimelineView(.animation)`. The wave's ripple is dropped under Reduce Motion.
- `FocusTool.swift`: `FocusTimer.shared` (observable, persisted end time in `focusEnd`, duration in `focusMinutes`) and `FocusView`, laid out after the reference pill: big MM:SS, 24 amber segments, "focus block · 25 min · ends 3:10 pm", "end focus".
- `Theme.swift`: colors (shared accents with MacRecordWidget, plus breath teal and focus amber) and the drawn enso template image.
- `PanelSizer.swift`: copied from MacRecordWidget, minus its `PanelScale`. Resizes the panel to the measured content.

### Adding a tool

1. New file conforming to `ShoshinTool`. Its `id` is persisted: never rename a shipped id.
2. Add it to `ToolRegistry.all`.
3. Add the file to `Shoshin.xcodeproj/project.pbxproj` by hand: `PBXBuildFile`, `PBXFileReference`, the `Shoshin` group's `children`, and the Sources build phase. The project uses classic file references, not synchronized groups (Xcode 15.2 cannot read those).

Any state that must outlive the panel (like the focus countdown) belongs in a shared object, not the view: the panel's views are torn down when it closes.

## Gotchas

- **AppKit grows the panel but never shrinks it.** The accordion changes height in both directions, which is why `PanelSizer` exists. Never animate the window resize; only the content animates. Details in MacRecordWidget's CLAUDE.md, "Panel sizing gotchas".
- **Swift 5.9 on CI.** Local `swiftc` is newer and accepts things CI rejects. Keep explicit `@MainActor` on `App` and on `FocusTimer`.
- **The focus ticker runs in `.common` run loop mode**, so the menu bar countdown keeps moving while a menu is tracking.
- `design/mocks.html` holds the HTML mocks the layout was chosen from (option A, accordion, with the Wave animation). `design/opt-*.html` are generated from it with `sed` on the `VARIANT` constant.
