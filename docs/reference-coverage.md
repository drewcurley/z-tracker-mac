# Reference feature-coverage audit (vs Zelda1RandoTools v1.3.1)

Cross-reference of the reference app's docs (`Zelda1RandoTools/doc/*`) against what
`z-tracker-mac` has shipped. **Originally generated 2026-07-16 (~T-078); refreshed
2026-07-21 (at T-165); reconciled 2026-07-28 against the task list through T-179.** This is
the canonical "what's left" list for parity — pull items into `tasks/` as they're picked
up, and update status here.

> **2026-07-28 headline:** the three former "biggest pillars" — **HotKeys**, **Broadcast
> window**, and the **Timeline graph** — have all shipped (HotKeys T-130–135/T-168/T-169/
> T-170; Timeline OW-progress graph T-099; Broadcast as a re-scoped mirror window T-178).
> The app is at functional parity. What remains is the smaller polish/niche list in §1–§2;
> none of it is load-bearing.

Legend: **S/M/L** = rough size.

## 1. Not started — genuinely absent (verified 0 code hits)

| # | Feature | Description | Doc | Size |
|---|---------|-------------|-----|------|
| 9 | **Circle overworld tiles** | Middle-click circle a tile; shift-left add label char; scroll/shift-right change color. | use §circle-overworld | M |
| 17 | **Highlight potential dungeon continuations** | Hover BLOCKERS label → highlight bombable/boss-blocked/meat-block/unvisited-doorway rooms. | use §main-hpdc | M |
| 20 | **Notes.txt auto-population** | Notes box pre-filled at startup from `~/Documents/ztracker/Notes.txt` (reuse `GameSave.defaultDirectory`, where `last-session.json` already lives). *(Kept 2026-07-28. Low urgency — Notes already persist (T-164/165) — but wanted for external note templates.)* | use §main-notes | S |
| 22 | **Zelda-finish → completion screenshots** | Clicking Zelda saves completion screenshots. *(The finish-time → Notes half is done, T-107.)* | use §main-oia | S |
| 3b | **In-menu hotkey hints** | Inline hotkey hints shown in menus. The only unshipped slice of HotKeys — the cheat-sheet window was dropped (§4). | use §hotkeys | S |

### Re-scoped 2026-07-28 — seed/flags + spoiler (moved up from "likely never"; research-gated)

The user wants automatic seed knowledge, in two related-but-separable pieces. **Both need a research
pass first** — do NOT invent formats; read the original `Zelda1RandoTools` source and the Z1R
randomizer (and z1r.fandom.com) to nail down exact encodings ([[z1r-wiki]], [[z-tracker-conversion-goal]]).

- **Spoiler-file importer** *(the higher-value, macOS-friendly half — L).* Import the Z1R randomizer's
  generated **spoiler file** and auto-mark everything (overworld caves/items, dungeon locations +
  contents — "marks it all for you"). File-based, so no fragile OS snooping. **Research:** the
  randomizer's spoiler-file format (structure + how entries map to this app's overworld/dungeon model).
- **Seed/flags snoop** *(M).* Read the emulator **window title** to auto-detect the seed + flag string
  (the reference's "snoop"). **Research:** how the original z-tracker parses the title + how the
  randomizer encodes the flag string (title / ROM name). The window-title read is the macOS-fragile
  part; the flag-string decode is the reusable, portable part — and could also drive auto-applying the
  right startup flags.

## 2. Partial — built, needs finishing

| Feature | Shipped | Remaining | Size |
|---------|---------|-----------|------|
| **Dungeon Summary tab** | All-9 overview + click-select (T-019.9) | 3 modes (preview/detail/default) + hover-preview over Notes + per-dungeon monster-priority list | M |
| **Progress popouts** | Inventory/Max-Hearts HUD (T-035.10) + Spot-Summary hover (T-053) | Click-to-popout for Spot Summary & Remaining Items + Max-Hearts hover trigger | S |
| **Save/Load** | Manual Save/Load, ~60s autosave, startup resume, quit Save/Don't-Save/Cancel (T-164/T-165) | Optional Phase 3: wire save-on-completion; add starting-items config + timeline history to the save | — |
| **Specific-Blockers** | Blocker UI + kinds (T-017/019.2/090) | *Decision needed:* only the "tiny-icon projection over the dungeon item boxes" is unbuilt — the **"applies to" half was deliberately dropped** (see §4). May be a no-op. | S |

## 3. Completed (since the original audit)

**The three former pillars — now done:**
- **Timeline (full)** — item-acquisition strip + splits + finish (T-098), **overworld-progress
  line graph (T-099)**, hover split/location (T-114), actual-pickups + hearts/bait (T-113),
  finish→Notes (T-107), hover label + magical-sword (T-119), QA round-2 (T-118). Broken-out
  window (T-100). *(This was the "Timeline graph" pillar — shipped.)*
- **HotKeys (full system, minus the cheat-sheet)** — config model + editor + import/export
  (T-130/131), Global runtime dispatch (T-132/132.1), keyboard cursor + region cycle
  (T-133/134/135), hover-driven contexts + hint/dungeon-item/Notes regions (T-168), per-context
  smarts incl. Unmark–Remark chains (T-169), editor + voice-editor navigation filters
  (T-170/T-170.1). *Remaining sliver: cheat-sheet window + in-menu hints (§1, #3b).*
- **Broadcast window** — shipped as a **re-scoped mirror** (T-178): a synced full-tracker
  second window + per-window breakout + Info-panel/app-icon toggles. The reference's
  mouse-position auto-switching mode was deliberately **not** cloned (§4, [[broadcast-window-rethink]]).

**Other completed since the audit:**
- **Dungeon room-map GRAB** — cut/paste model (T-073) + grab-mode/drag-drop/keep-undo/cancel
  interaction (T-083); **user-verified on-device 2026-07-28**.
- **Save / Load state** — T-164 (serialization core) + T-165 (UI/autosave/resume/quit dialog).
- **Speech / voice recognition** (#11) — fully built (T-137→T-159): on-device grammar,
  cursor-driven region-aware marking, editable command set, dungeon/blocker/item/overworld vocab.
- **Custom waypoint** (#13) — T-162.
- **Reminder log** (#14) — `ReminderLogView` (T-102/T-122/T-125).
- **Dungeon row-location assistance** (#18) — `RowLocatorWidget` (T-078/T-078.1).
- **LEGEND version/website button** (#23, half) — T-163 (Settings → About).
- **Custom-map import + per-tile fog-of-war** — T-167 (beyond parity; covers the useful part
  of the "other randomizers" suite, #21).
- **Higher-fidelity game sprites + app icon** — T-161 (beyond parity).
- **Dungeon-hover FPS + file-based render-perf logging** — T-179 (perf/diagnostics).

**Beyond-reference product / infra (not parity gaps, logged for completeness):**
- **Custom dungeon-label rename** (LEVEL → any prefix) — T-171.
- **Distribution** — update-on-launch notice + DMG packaging + notarization-ready build (T-174);
  app naming/credits/version (T-172/T-173/T-175); startup-button sizing + load wiring (T-177).

## 4. Descoped / not planned

- **LEGEND block** (#23) — **killed (user, 2026-07-28):** a single-use legend that permanently
  occupies map space; players quickly learn what their own marks look like by making them. Nothing
  depends on it — the recorder destination (the only consumer of LEGEND numbers) is already handled
  by the recorder widget/stepper (T-035.7/T-081/T-093/T-104).
- **Remaining-items hover** (#16) — **killed (user, 2026-07-28):** redundant with the existing
  right-click item picker, which already shows what could appear in an empty box.
- **Mouse-hover explainer** (#10) — **killed (user, 2026-07-28):** a one-time-use '?' diagram that
  explains hover targets; self-explanatory once you click around. Per the user's design rule — *if you
  have to explain how to use the app, it isn't intuitive enough* — an in-app how-to is a smell, not a
  feature.
- **Hotkey cheat-sheet window** (part of #3b) — **dropped (user):** not needed; the in-menu inline
  hints (§1, #3b) are the only wanted piece.
- **Broadcast auto-switching mode** (was the #2 "remaining") — **re-scoped (user):** replaced by
  the mirrored main window + independent breakouts (T-178). The reference's fixed-layout window
  that auto-switches OW/dungeon by mouse position is deliberately **not** cloned ([[broadcast-window-rethink]]).
- **Blocker "applies to" / specific-blocker reward mapping** — **dropped (user, 2026-07-15):** with a
  real block you usually don't know what's behind it; a blocker is just "couldn't get past X here."
  The model's `appliesTo` accessors remain unused (harmless, matches the reference save schema).
- **Special-NPC room outlines + tab dots** (was #19) — **dropped (user, 2026-07-21):** the standout
  custom room tile already makes bomb-upgrade / NPC-hint rooms obvious.
- **Link — on-demand routing** (was #5) — **dropped (user, 2026-07-22):** "most experienced players
  know how to route the map." The GYR accessibility highlight (T-015.4) covers what's useful.
- **Take-Any pie menu** (#8) — the clone edits take-any directly (deliberate deviation); the radial
  accelerator is niche and not planned.
**Deprioritized — may not do (user, 2026-07-28):** not formally killed, but unlikely to be built.
- **Overworld magnifier** (#6) — hover → magnified nearby view + Lost Woods/Hills maze hints.
- **Mouse magnifier window** (#7) — separate mouse-following magnifier window.
- **Show/Run Custom** (#12) — `ShowRunCustom.txt` launcher for image windows / exes+URLs.
- **HFQ / HSQ buttons** (#15) — hide first/second-quest spot pruning after quest discovery.
- **"Other randomizers" suite remnant** (#21) — draw-your-own map, Draw layer, custom checklist.
  *(The custom-map-from-disk part already shipped, T-167.)*

## 5. Intentional deviations (not gaps)

- **Default file location = `~/Documents/ztracker/`** (`GameSave.defaultDirectory`) — the single
  default home for app-generated files (saves + `last-session.json` today; `Notes.txt` #20, and any
  future exports/logs), unless the user explicitly chooses another location. New file-producing
  features should default here rather than inventing their own path.
- **App size/shape presets** (Tall/Square/2·3/5·6) — replaced by responsive layout (ADR 0003).
- **Coast item ≠ ladder**, **4-state take-any hearts**, **no marked-room drag-eraser** — deliberate
  rules (see memory).
- **No hotkey mouse-warping / click emulation** (user, 2026-07-22) — the reference nudges the OS
  pointer 20px off-grid and recenters it between regions. The keyboard cursor (T-134/135/168) serves
  the same purpose semantically, and synthetic clicks would require an Accessibility (TCC) grant the
  user would have to re-approve after every rebuild.
- **Hotkey context = hover, with the keyboard cursor as fallback** (T-168) — the reference keys purely
  off mouse hover. Both are supported here; a deliberate keyboard nav overrides a resting mouse.

## 6. Beyond the reference — planned user requests (not in the original audit)

- **"Make a note {X}" voice command** — append dictated text to the NOTES field (buildable with
  Speech.framework free-form dictation). *(Not yet built.)*

## What's actually left

No pillars remain — the app is at functional parity. The newly **re-scoped** work is the headline:
the **spoiler-file importer** (+ seed/flags snoop), research-gated (§1). Beyond that the **active
candidate list** (§1) is short: circle-overworld-tiles (#9), dungeon-continuation highlight (#17),
completion screenshots (#22), in-menu hotkey hints (#3b), and Notes.txt auto-population (#20) — plus
the optional §2 finishing (Dungeon Summary modes, progress popouts, Save/Load Phase 3). Everything
else is **deprioritized** or **descoped** (§4). Pick from §1/§2 for the next feature; check this file
before scoping.
