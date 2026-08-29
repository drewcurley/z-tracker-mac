# Changelog

All notable changes to **Z-Tracker for macOS**. Newest first. This project follows
[Keep a Changelog](https://keepachangelog.com/) and [Semantic Versioning](https://semver.org/).
Each entry mirrors the notes on its [GitHub Release](https://github.com/drewcurley/z-tracker-mac/releases).

## [1.2.4] — 2026-08-28
### Fixed
- The dungeon room, monster, and floor-drop choosers and the overworld enemy chooser now show a
  **live header label** naming whatever option you hover — matching the graphical tile chooser.
- The room chooser now spells it **Ganon** (was "Gannon").

## [1.2.3] — 2026-08-27
### Added
- **Drop Rooms** window (button in the Info area, between Hint Decoder and Settings): shows the room
  layouts that never hold a floor drop in the dungeon selected on the Dungeon Map tab, updating live.
### Changed
- Hint Decoder: the **"Other hints"** title now toggles the section, not just the chevron.

## [1.2.2] — 2026-08-27
### Added
- **Shop & Price tracker** breakout window: 4 shops × 3 staple slots (left-or-right-click picker,
  graphical or menu per your chooser setting), two potion prices, a bomb-upgrade price, and the six
  paid hints with a "collected" check. Saved with the game.
- The Info overlay-icon row is now four wide; a **cart** icon opens the shop window and the
  **Commentary** toggle moved there as a checkered-flag icon (no extra vertical space).
### Changed
- The **bomb-upgrade icon** is now the real bomb sprite with a green "+", everywhere it appears
  (swordless seeds and the shop window), replacing the old low-res glyph.

## [1.2.1] — 2026-08-27
### Added
- **"Bomb Droppers"** overworld enemy marker — a generic bomb icon for any screen whose enemies drop
  bombs. Available from the graphical enemy picker and the right-click enemies menu.

## [1.2.0] — 2026-08-27
### Added
- **Commentary Mode** — a commentator-only overlay tracking which of two runners has seen each
  element across five surfaces (overworld tiles, dungeon item boxes, the item grid, room maps, and
  blockers). ⌥-click = Runner 1, ⌥-right-click = Runner 2; corner-pip or edge-border encoding;
  per-session runner names and colors; never shown on the stream layout.
### Changed
- The **Spot Summary** breakout window now scales as you resize it, and its icons use the current
  game sprites (matching the overworld map).
- The dungeon-map room "circle"/brightness (and door "yellow") moved from ⌥ to **⌘-click / ⌘-drag**,
  so ⌥ is the Commentary key everywhere.

## [1.1.2] — 2026-08-27
### Changed
- Smarter defaults for gated items: the coast item stays untaken until you have the **ladder**; the
  White Sword item defaults untaken below **4 hearts**; the Magical Sword can't be marked held below
  **10 hearts**. Above the minimums, your clicks are trusted as before.

## [1.1.1] — 2026-08-25
### Changed
- **Now notarized by Apple** — no more right-click → Open or "Open Anyway" on first launch.
- Sword caves use the real game sword sprites on the overworld (the last of the placeholder icons).
### Notes
- One-time manual install for anyone on v1.0.0 / v1.1.0: those were self-signed, and the updater
  won't swap an app for one signed by a different identity. Auto-update works automatically from
  v1.1.1 onward.

## [1.1.0] — 2026-08-25
### Added
- **Heart Shuffle is 3-way** (Off → Intra → Full). Intra-dungeon shuffle deduces the heart: once a
  dungeon's other items are identified, the heart auto-appears (dimmed, untaken) in the remaining slot.
- **Unwanted items** show a large X across the whole box, with a setting to switch back to the small
  corner X.
### Changed
- Shops drop the orange background — item sprites fill the tile with a drop-shadow (the chooser too).
- Bigger location-hint chips and triforce markers.
- Marking a White/Magical-Sword cave auto-fills its location hint to that region.

## [1.0.0] — 2026-08-24
### Added
- **In-app auto-update** (Sparkle): **Check for Updates…** downloads, verifies (EdDSA-signed),
  replaces, and relaunches in place.
### Notes
- One-time manual install: older copies don't have the updater yet. From v1.0.0 onward, updates are
  one click.

## [0.9.2] — 2026-08-23
### Fixed
- The run **timeline always fills the window** now — a short/new run uses the full pane width instead
  of sitting in a corner.

## [0.9.1] — 2026-08-23
### Fixed
- The run **timeline fits the whole run**: long games no longer drew off the right edge. The minute
  axis grows its step as the game lengthens, icons stack instead of overlapping, and it rescales live
  on resize. (Display-only; no data was ever lost.)

## [0.9.0] — 2026-08-21
### Added
- **Shop per-item hiding**: owned items drop from a combo shop; an all-owned shop dims out and
  reveals on hover (consumables stay visible).
- **Confirmation sounds** (Settings): a voice chime on a recognized command and an input tick on
  mouse/keyboard edits, each with its own volume.
- **Tile-change animation** (Settings) and an **"Auto-save and quit"** option.
### Changed
- The dungeon location-hint picker updates its label as you hover each zone; settings save immediately.

## [0.8.4] — 2026-08-20
### Added
- Left-click F16 (the coast screen) opens the coast-item picker directly.
- Graphical tile chooser: a live hover label, and it's on by default for new installs.

## [0.8.3] — 2026-08-18
### Fixed
- **Crash on launch on macOS 15 (Sequoia)**, both architectures — resources now load by direct file
  path instead of the `Bundle.module` API that Sequoia rejected. (Supersedes v0.8.0–v0.8.2.)

## [0.8.2] — 2026-08-18 — superseded
### Fixed
- An attempt at the Sequoia launch crash (resource-bundle `Info.plist`); did not fully cover it —
  use v0.8.3.

## [0.8.1] — 2026-08-18
### Added
- A **dedicated native Intel build** alongside Apple Silicon; the Spot Summary pop-out window and
  in-menu hotkey hints.

## [0.8.0] — 2026-08-18
- First tester build: overworld + dungeon tracking, item/hint/blocker tracking, audio + visual
  reminders, voice control, a run timer with crash-recovery resume, save/load + autosave, spoiler-log
  import, custom-map fog-of-war, Dark/Light/OS themes, rebindable hotkeys with in-menu hints, and a
  broadcast mirror window for streaming.

[1.2.4]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v1.2.4
[1.2.3]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v1.2.3
[1.2.2]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v1.2.2
[1.2.1]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v1.2.1
[1.2.0]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v1.2.0
[1.1.2]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v1.1.2
[1.1.1]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v1.1.1
[1.1.0]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v1.1.0
[1.0.0]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v1.0.0
[0.9.2]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v0.9.2
[0.9.1]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v0.9.1
[0.9.0]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v0.9.0
[0.8.4]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v0.8.4
[0.8.3]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v0.8.3
[0.8.2]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v0.8.2
[0.8.1]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v0.8.1
[0.8.0]: https://github.com/drewcurley/z-tracker-mac/releases/tag/v0.8.0
