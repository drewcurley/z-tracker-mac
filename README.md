# Z-Tracker for macOS

A native Apple-Silicon macOS tracker for **The Legend of Zelda: Randomizer (Z1R)** — a
spiritual successor to [Z-Tracker](https://github.com/brianmcn/Zelda1RandoTools) by
Dr. Brian Lorgon111, rebuilt from the ground up as a real Mac app (SwiftUI, no emulation
layer, no Windows compatibility shims).

It keeps track of everything you'd otherwise hold in your head during a run: what's on each
overworld screen, what you've found in each dungeon, which items you have, where your hints
point, and what's blocking you — with audio/visual reminders, a run timer, and voice control
so you can keep your hands on the controller.

---

## Requirements

- An **Apple-Silicon Mac** (M1 or newer)
- **macOS 14 (Sonoma) or later**

## Install

1. Download the latest `ZTrackerMac-<version>.dmg` from the
   [Releases page](https://github.com/drewcurley/z-tracker-mac/releases).
2. Open the DMG and drag **ZTrackerMac** into your **Applications** folder.
3. **First launch:** the app isn't signed with an Apple Developer ID yet, so macOS
   Gatekeeper will block a plain double-click. To open it the first time:
   **right-click the app → Open → Open**. macOS remembers your choice, so every launch after
   that is a normal double-click.

## Getting started

Launch the app and pick how you want to start:

- **A quest overworld** — First, Second, or Mixed. This is the usual choice.
- **A previously saved run** — resume from a save file.
- **A custom overworld map** — drop in your own map image (e.g. from an alternate-overworld
  generator) and play with every screen hidden under fog until you reveal it.

The startup screen also holds the settings (theme, reminders, hotkeys, and more). If a run
from a previous session was auto-saved, the app offers to reopen it — handy after a crash.

## Features

**Overworld map**
- Mark every screen: dungeons, warp/any-road caves, sword caves, shops (with a second item),
  the four secret sizes, take-any caves, door-repair, the money game, the letter, armos, hint
  and potion shops, and "nothing here."
- A graphical or text tile chooser, quick left-click marking, and per-kind hiding once
  things are no longer relevant.
- Route/"get-your-stuff" highlighting, an open-caves overlay, and a mirrored-overworld option.

**Dungeon tracker**
- Per-dungeon room maps (room types, doors, floor items, monsters), item boxes, triforce and
  "you can whistle here" state, and blockers ("need bombs / ladder / bow…").
- Drag to swap floor↔basement item boxes; per-dungeon notes.

**Items, hints & progress**
- A full item grid with seed flags (Heart Shuffle, Hidden Dungeon Numbers, swordless,
  boomstick book, mirrored, "book for hints").
- Location hints per dungeon and per sword cave, a hint decoder, and a "spot summary" of
  what's left to find.
- A faux in-game inventory/hearts HUD you can pop out into its own window.

**Reminders & voice**
- Spoken and on-screen reminders (e.g. "you have the recorder," "consider the boomstick
  book," "grab the armos item"), each toggleable by category, plus a reminder log.
- **Voice control:** mark the board, move the cursor, switch dungeons, start/pause the timer,
  and step the recorder destination — all hands-free, with an editable command set.

**Run timer**
- A pausable main timer plus a lap/groundhog timer, with splits recorded to a run timeline.
- Crash recovery: reopen and the timer resumes automatically; choose whether a reopened run
  counts active time or real time since it began.

**Save / load**
- Manual save/load, ~60-second autosave, resume-on-launch, and an optional auto-save when you
  finish a run. Files live in `~/Documents/ztracker/`.

**Spoiler import**
- Import a Z1R randomizer spoiler log to auto-mark the whole board — overworld caves/items and
  dungeon locations, contents, and room maps.

**Extras**
- Dark / Light / follow-the-OS themes.
- Fully re-bindable hotkeys (hover a region, press a key) with the bound key shown right in
  the menus, plus a hotkey/voice-command editor.
- A broadcast **mirror window** for streaming, with independent breakout windows.
- Check-on-launch notice when a newer version is available.

## Files & data

Everything the app writes lives in **`~/Documents/ztracker/`**:

- `last-session.json` — the rolling autosave used for resume/crash-recovery.
- Your manual saves (`ztracker-<date>.json`) and completion saves (`ztracker-completed-…`).
- `Notes.txt` *(optional, you create it)* — its contents pre-fill the Notes box at the start
  of each run, so you can keep a personal checklist template.

## Credits

The original **Z-Tracker** and the Zelda 1 Randomizer tracking design are by
**Dr. Brian Lorgon111** — see [Zelda1RandoTools](https://github.com/brianmcn/Zelda1RandoTools).
This macOS app is an independent, from-scratch reimplementation inspired by that work; all
game names and imagery belong to their respective owners.
