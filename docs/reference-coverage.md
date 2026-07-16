# Reference feature-coverage audit (vs Zelda1RandoTools v1.3.1)

Full cross-reference of the reference app's docs (`Zelda1RandoTools/doc/*`) against
what `z-tracker-mac` has shipped (`tasks/INDEX.md` + `Sources/`). Generated
2026-07-16. This is the canonical "what's left" list for parity — pull items from
here into `tasks/` as they're picked up.

Legend: **S/M/L** = rough size.

## 1. MISSING — documented, no implementation

| # | Feature | Description | Doc | Size |
|---|---------|-------------|-----|------|
| 1 | **Timeline** | Item-acquisition history strip + OW-progress-over-time graph; per-item second splits; finish-time capture. Placeholder only. | use §main-timeline | L |
| 2 | **Broadcast window** | Separate squarer stream window auto-switching OW/dungeon by mouse pos; 1/3·2/3·full. Options+panel exist; no window created. | extras §broadcast; stream-capture | L |
| 3 | **HotKeys (whole system)** | `HotKeys.txt` bindings per context, arrow-nav, click-emulation, cheat-sheet window, popup hints. Only naming tokens exist. (stub) | extras §hotkeys | L |
| 4 | **Save / Load state** | Save full state to file, load at startup, ~1-min autosave, save-on-completion. Only settings/window persist. (pinned) | extras §save-state | L |
| 5 | **Link (on-demand routing)** | Click Link → pick destination → draw best path(s) ~10s incl. ambiguous-hint routing. Backlog T-015.6. | use §main-link | M |
| 6 | **Overworld magnifier** | Hover a tile → magnified nearby view + Lost Woods/Hills maze hints + legend. `showMagnifier` toggle only. | use §main-owm | M |
| 7 | **Mouse magnifier window** | Separate mouse-following magnifier window. Toggle only. | whats-new v13 | M |
| 8 | **Take-Any pie menu** | Radial pie-menu accelerator (warp cursor to center, pick, warp back). Clone edits take-any directly; pie UI absent. | use §take-any-accelerator | M |
| 9 | **Circle overworld tiles** | Middle-click circle a tile; shift-left add label char; scroll/shift-right change color. Not in OW model/view. | use §circle-overworld | M |
| 10 | **Mouse-hover explainer** | '?' near the timer revealing a diagram of every hover target. Absent. | use §general-mouse-hover | S |
| 11 | **Speech recognition** | "tracker set {bomb shop / level one / …}" voice marking. `listenForSpeech` toggle only. | use §speech-recognition | L |
| 12 | **Show/Run Custom** | `ShowRunCustom.txt` button to show image windows / run exes+URLs, persisted positions. Absent. | use §main-buttons | M |
| 13 | **Custom waypoint** | A second freely-placeable Start-Spot-like marker. Absent. | whats-new v13 | S |
| 14 | **Reminder log** | "log" button (timeline upper-right) showing past reminders / beep explanations. Absent. | whats-new v13 | S |
| 15 | **HFQ / HSQ buttons** | Hide-First/Second-Quest to prune mixed-quest spots after discovering the quest. Absent. | use §hfq-hsq | M |
| 16 | **Remaining-items hover** | Hover an empty item box → popup of items that could still appear there. Absent. | whats-new v13 | S |
| 17 | **Highlight potential dungeon continuations** | Hover BLOCKERS label → highlight bombable/boss-blocked/meat-block/unvisited-doorway rooms. Absent. | use §main-hpdc | M |
| 18 | **Dungeon row-location assistance** | Rupee/blank/key/bomb icons beside the dungeon map; highlight follows the hovered room's row + column letter. Absent. **(user-requested next)** | use §main-dungeon-row-location | S |
| 19 | **Special-NPC room tab dots / colored outlines** | Bomb-Upgrade (blue) / NPC-Hint (red) room outlines + matching dungeon-tab dots + bait icon for Hungry-Goriya. Room types exist; surfacing doesn't. | use §main-dungeon-special-rooms | M |
| 20 | **Notes.txt default population** | Notes box pre-filled from `Notes.txt` at startup. | use §main-notes | S |
| 21 | **"Other randomizers" suite** | Alternative OW maps (draw-your-own / from-disk revealed/hidden), Draw (icons + ExtraIcons folder), User Custom Checklist. Niche. | other.md | L |
| 22 | **Zelda-finish → Notes text + screenshots** | Clicking Zelda posts finish time into Notes + saves completion screenshots. Timer-pause done; these aren't. | use §main-oia | S |
| 23 | **LEGEND block + version button** | Map legend below OW (dungeon numerals, any-road icons) + clickable version/website button. | use §main-owm | S |

## 2. PARTIAL — built but incomplete

- **Blockers → Specific-Blockers**: base UI+model done (T-017/019.2); missing the specific-blocker checklist submenu + tiny-icon projection over the dungeon item boxes.
- **Dungeon Summary tab**: 3×3 + click-select done (T-019.9); missing the 3 modes (preview/detail/default) + hover-preview over Notes + per-dungeon monster-priority list.
- **Progress popouts**: inventory/Max-Hearts HUD (T-035.10) + Spot-Summary hover (T-053) done; missing click-to-popout for Spot Summary & Remaining Items + Max-Hearts hover trigger.
- **GRAB**: cut/paste model done (T-073); no UI (button/mode/drag-drop/preview/undo).
- **Recorder-destination ↔ LEGEND coupling**: stepper done (T-035.7); the LEGEND-number cycling is unbuilt (blocked on #23).
- **Snoop seed/flags**: options exist; no emulator window-title snooping (macOS-specific; likely deferred).
- **Spot Summary counts**: exists (T-053) but is missing per-type "left" counts (door-repair, money-making-game, hints, take-any, shops bomb/candle/ring/meat) — user-flagged.

## 3. Intentional deviations (not gaps)

- **App size/shape presets** (Tall/Square/2·3/5·6) — replaced by responsive layout (ADR 0003).
- **Coast item ≠ ladder**, **4-state take-any hearts**, **no marked-room drag-eraser** — deliberate rules (see memory).

## Biggest remaining pillars
**Timeline · Broadcast window · HotKeys · Save/Load** — the four large documented systems with essentially no runtime yet (the latter three have option/model scaffolding only).
