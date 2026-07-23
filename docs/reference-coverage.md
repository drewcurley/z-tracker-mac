# Reference feature-coverage audit (vs Zelda1RandoTools v1.3.1)

Cross-reference of the reference app's docs (`Zelda1RandoTools/doc/*`) against what
`z-tracker-mac` has shipped. **Originally generated 2026-07-16 (~T-078); fully refreshed
2026-07-21 (verified against code at T-165).** This is the canonical "what's left" list
for parity — pull items into `tasks/` as they're picked up, and update status here.

Legend: **S/M/L** = rough size.

## 1. Not started — genuinely absent (verified 0 code hits)

| # | Feature | Description | Doc | Size |
|---|---------|-------------|-----|------|
| 6 | **Overworld magnifier** | Hover a tile → magnified nearby view + Lost Woods/Hills maze hints + legend. Only the `showMagnifier` toggle exists. | use §main-owm | M |
| 7 | **Mouse magnifier window** | Separate mouse-following magnifier window. Only the toggle exists. | whats-new v13 | M |
| 9 | **Circle overworld tiles** | Middle-click circle a tile; shift-left add label char; scroll/shift-right change color. | use §circle-overworld | M |
| 10 | **Mouse-hover explainer** | '?' near the timer revealing a diagram of every hover target. | use §general-mouse-hover | S |
| 12 | **Show/Run Custom** | `ShowRunCustom.txt` button to show image windows / run exes+URLs, persisted positions. | use §main-buttons | M |
| 15 | **HFQ / HSQ buttons** | Hide-First/Second-Quest to prune mixed-quest spots after discovering the quest. *(Verify exact quest-pruning rules against the reference before building.)* | use §hfq-hsq | M |
| 16 | **Remaining-items hover** | Hover an empty dungeon box → popup of items that could still appear. *(Largely redundant with the existing right-click picker.)* | whats-new v13 | S |
| 17 | **Highlight potential dungeon continuations** | Hover BLOCKERS label → highlight bombable/boss-blocked/meat-block/unvisited-doorway rooms. | use §main-hpdc | M |
| 20 | **Notes.txt auto-population** | Notes box pre-filled from a file at startup. *(Needs a decision on the macOS file location.)* | use §main-notes | S |
| 22 | **Zelda-finish → completion screenshots** | Clicking Zelda saves completion screenshots. *(The finish-time → Notes half is done, T-107.)* | use §main-oia | S |
| 23 | **LEGEND block** | Map legend below the OW (dungeon numerals, any-road icons). *(The version/website-button half shipped — T-163.)* | use §main-owm | S |
| 21 | **"Other randomizers" suite** | Alternative OW maps (draw-your-own / from-disk revealed/hidden), Draw layer, User Custom Checklist. Niche. *(The custom-map-from-disk part shipped as T-167; draw-your-own, Draw layer, and the custom checklist are not planned.)* | other.md | L |

## 2. Partial — built, needs finishing

| Feature | Shipped | Remaining | Size |
|---------|---------|-----------|------|
| **Timeline** (#1) | `GameTimelineView` + `TimelineModel` per-second recording + broken-out window (T-098) | OW-progress-over-time graph; confirm per-item splits + finish capture vs the reference | L |
| **Broadcast window** (#2) | Options + settings panel + size enum | The actual separate window that auto-switches OW/dungeon by mouse position | L |
| **HotKeys** (#3) | Config editor, Global dispatch, cursor-nav (T-130–135); hover-driven contexts, hint-zone + dungeon-item + Notes regions (T-168) | The per-context "smarts" incl. Unmark–Remark chains (T-169); cheat-sheet window + in-menu hotkey hints (T-170) | M |
| **GRAB** | Cut/paste model + **grab mode + GRAB button + click pick/drop** (T-073 + controller) | Confirm the reference's drag-drop preview + undo (may already be enough) | S |
| **Blockers → Specific-Blockers** | Base blocker UI+model (T-017/019.2) | Specific-blocker checklist submenu + tiny-icon projection over the dungeon item boxes | M |
| **Dungeon Summary tab** | 3×3 + click-select (T-019.9) | 3 modes (preview/detail/default) + hover-preview over Notes + per-dungeon monster-priority list | M |
| **Progress popouts** | Inventory/Max-Hearts HUD (T-035.10) + Spot-Summary hover (T-053) | Click-to-popout for Spot Summary & Remaining Items + Max-Hearts hover trigger | S |
| **Recorder-destination ↔ LEGEND** | Stepper (T-035.7) | The LEGEND-number cycling (blocked on the LEGEND block, #23) | S |
| **Spot Summary per-type counts** | "Non-unique locations" section shows per-type remaining counts (T-053) | *Verify* it covers all listed types (door-repair, money-game, hints, take-any, shop bomb/candle/ring/meat); if so this is done | S |
| **Save/Load** | Manual Save/Load, ~60s autosave, startup resume, quit Save/Don't-Save/Cancel (T-164/T-165) | Optional Phase 3: wire save-on-completion; add starting-items config + timeline history to the save | — |

## 3. Completed since the original audit

- **Save / Load state** — T-164 (serialization core) + T-165 (UI/autosave/resume/quit dialog).
- **Speech / voice recognition** (#11) — fully built (T-137→T-159): on-device grammar, cursor-driven region-aware marking, editable command set, dungeon/blocker/item/overworld vocab. *(The old audit listed this as "toggle only.")*
- **Custom waypoint** (#13) — T-162.
- **Reminder log** (#14) — `ReminderLogView`.
- **Dungeon row-location assistance** (#18) — `RowLocatorWidget` (T-078/T-078.1).
- **LEGEND version/website button** (#23, half) — T-163 (Settings → About).
- **Custom-map import + per-tile fog-of-war** — T-167 (beyond parity, user request): import a custom OW map, every screen fogged until marked; vanilla dead spots / fairies / GYR / routing off, fairies hand-placed. Covers the useful part of the "other randomizers" suite (#21).
- **Higher-fidelity game sprites + app icon** — T-161 (beyond parity: replaced the crude atlases with real game sprites).

## 4. Descoped / not planned

- **Special-NPC room outlines + tab dots** (was #19) — **dropped (user, 2026-07-21):** the standout custom room tile already makes bomb-upgrade / NPC-hint rooms obvious, so the colored outlines + tab dots + hungry-goriya bait icon aren't needed.
- **Link — on-demand routing** (was #5) — **dropped (user, 2026-07-22):** "most experienced players know how to route the map." The GYR accessibility highlight (T-015.4) already covers what's actually useful; the path-drawing half isn't planned.
- **Take-Any pie menu** (#8) — the clone edits take-any directly (a deliberate deviation); the radial accelerator is niche and not planned.
- **Snoop seed/flags** — reads an emulator's window title; macOS-specific with no clean equivalent. Deferred / likely never.

## 5. Intentional deviations (not gaps)

- **App size/shape presets** (Tall/Square/2·3/5·6) — replaced by responsive layout (ADR 0003).
- **Coast item ≠ ladder**, **4-state take-any hearts**, **no marked-room drag-eraser** — deliberate rules (see memory).
- **No hotkey mouse-warping / click emulation** (user, 2026-07-22) — the reference nudges the OS pointer 20px off-grid and recenters it between regions. The keyboard cursor (T-134/135/168) serves the same purpose semantically, and synthetic clicks would require an Accessibility (TCC) grant the user would have to re-approve after every rebuild.
- **Hotkey context = hover, with the keyboard cursor as fallback** (T-168) — the reference keys purely off mouse hover. Both are supported here; a deliberate keyboard nav overrides a resting mouse.

## 6. Beyond the reference — planned user requests (not in the original audit)

- **"Make a note {X}" voice command** — append dictated text to the NOTES field (buildable with Speech.framework free-form dictation).

## Biggest remaining pillars

**HotKeys full system · Broadcast window · Timeline graph** — the user's three chosen
pillars. Save/Load, Voice, and custom-map fog-of-war are done; Link on-demand routing was
descoped (§4).
