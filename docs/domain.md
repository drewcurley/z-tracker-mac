# Domain — z-tracker-mac (feature-parity inventory)

**Status:** grounded in the reference app (`Zelda1RandoTools`), not this repo's
(nonexistent) code. This is the **acceptance-criteria baseline** for "feature-by-
feature, near pixel-perfect clone" — every item below is something the clone is
expected to eventually replicate, unless a future ADR explicitly descopes it.

**Verification:** produced by a dedicated inventory pass over
`Zelda1RandoTools`'s `doc/*.md` and F# source (`Z1R_Tracker/`), 2026-07-02.
File/line citations below point into that repo. Re-verify against
`Zelda1RandoTools` directly if this ever seems stale — it is a pinned fork
(see `playbook/workspace.manifest.md`), so it will only change if intentionally
re-synced with `upstream`.

## 1. App purpose & audience

A manual, click-driven companion app run alongside an NES emulator to record
progress through a randomized Zelda 1 seed (fcoughlin's z1r randomizer):
dungeons found, items obtained, overworld locations marked, dungeon maps drawn.
Three audiences: **seed runners** (fast gesture entry), **stream viewers**
(always-on-screen summary + historical timeline), **z1r learners** (routing
help, reminders). (`Zelda1RandoTools/README.md:22-33`)

## 2. Core architecture of the reference app

Four F# projects (`Z1R_Tracker/Z1R_Tracker.sln`):
1. **`Z1R_Tracker`** — UI-agnostic core: `OverworldData.fs`, `DungeonData.fs`,
   `TrackerModelOptions.fs`, `TrackerModel.fs` (~100 KB), `OverworldRouting.fs`,
   `SaveAndLoad.fs`. This is the **logic spec** for the Swift rewrite.
2. **`Z1R_WPF`** — the shipped, most complete Windows UI. This is the
   **behavioral/UI reference** for parity (~40 files incl. `WPFUI.fs`,
   `DungeonUI.fs`, `Graphics.fs`, `Layout.fs`, `HotKeys.fs`, `Reminders.fs`).
3. **`Z1R_Avalonia`** — cross-platform UI, EOL toolchain, behind WPF in
   features (see `docs/decisions/0001-native-swiftui-over-avalonia-port.md`).
   Not a parity reference — WPF is newer/more complete.
4. **`Z1R_Tracker_NETCoreApp31`** — thin re-packaging used only by Avalonia;
   omits `TrackerModelOptions.fs`/`SaveAndLoad.fs`. Not a reference.

## 3. How the reference app gets game state

**Purely manual.** Confirmed no `ReadProcessMemory`/`OpenProcess`/emulator RAM
access anywhere in the core. The only cross-process behavior is an opt-in
setting (`SnoopSeedAndFlags`, `SaveAndLoad.fs:308-321`) that regex-scans other
windows' **title bars** (not memory) for a `_<seed>_<flags>` pattern purely to
auto-fill a display/save-metadata label. **Implication for this project:** no
emulator integration of any kind is required for feature parity.

## 4. Exhaustive feature inventory (the parity checklist)

### 4.1 Startup screen
- Heart Shuffle toggle, Hide Dungeon Numbers toggle
- 4 overworld-quest start buttons: First / Second / Mixed-First / Mixed-Second
  (spot counts: 1Q=73, 2Q=80, Mixed=93, "UQ"=128)
- Alternative overworld map mode: blank 16×8 grid, fully-revealed load, or
  hidden-until-clicked load
- "Start from previously saved state" (restores HS/HDN/OW from the save)
- Embedded options menu (note: "Listen for Speech" is startup-only — cannot be
  toggled on later in the reference app; confirm whether this constraint is
  worth carrying forward or was purely an implementation artifact)
- Window size/shape presets: Tall (default, 768×967), Square, 2/3, 1/3, 5/6
- Random tip/Factoid display; Konami-code easter egg reveals all tips

### 4.2 Dungeon Item Area (9 dungeons)
- Triforce click-toggle (have/not), located-hint highlighting, tiny
  force-overworld-blocker icon overlay
- 2–3 item boxes per dungeon (3 in Hide-Dungeon-Numbers mode): popup of 15
  items; left-click=have (green), right-click=don't-have (red/grayscale),
  middle-click=skip (purple X)
- "Starting Items & Extra Drops" popup (D9 ellipsis): starting items, shuffled
  minor/monster drops, max-hearts delta, HDN starting triforce pieces,
  triforce-decoder diagram

**The 15 trackable items:** BookOrShield, Boomerang, Bow, PowerBracelet,
Ladder, MagicBoomerang, AnyKey, Raft, Recorder, RedCandle, RedRing,
SilverArrow, Wand, WhiteSword, HeartContainer (×9 slots).

### 4.3 Other Item Area
White Sword / Coast / Armos boxes; Magical Sword, Wood Sword, Blue Candle,
Wood Arrow, Blue Ring (→ timeline on click); Bombs (enables bomb routing);
Boomstick Book + shield/book toggle; Ganon (→ timeline) / Zelda (→ stops timer,
posts finish time to Notes); 4 take-any hearts; Zones/Coords toggles; "N OW
spots left" + "N gettable" counters (hover = green/yellow/red breakdown); "Max
Hearts: N" (hover = inventory popup); open-cave indicator; timer with
pause/reset; hoverable spot summary; HFQ/HSQ buttons; potion-letter indicator;
rupee icon (hover = money-making-games/secrets); eyeball (hide map icons
toggle); mirror-overworld toggle; book-is-atlas toggle; WS/MS-to-Bomb-Upgrade
toggle; per-item "have I found X" box-outline coloring.

### 4.4 Routing ("Link" feature)
Pick a destination (specific tile, shop type, dungeon, WS/MS cave, or
remaining open caves) → app draws a route on the overworld map for ~10 seconds.
Handles ambiguous hinted locations via green/yellow/red (GYR) marking. This is
the reference app's original, most novel feature — the algorithm lives in
`OverworldRouting.fs`/`OverworldData.fs` (rule-by-rule detail not yet
transcribed — see § 6 open questions).

### 4.5 Overworld map (16×8 grid, 38 tile-mark types)
9 dungeons, 4 any-roads, 3 sword caves, 8 shops (Arrow/Bomb/Book/Candle/
BlueRing/Meat/Key/Shield), Unknown/Large/Medium/Small secret, DoorRepair,
MoneyMakingGame, Letter, Armos, HintShop, TakeAny, PotionShop, DarkX
(don't-care). Gestures: left-click dark tile / right-click unmarked → popup;
left-click unmarked → mark dark; left-click shop → add 2nd item; middle-click
→ circle tile (shift-variants for label/color); "take-any" pie-menu cursor-warp
accelerator; hover → magnifier + routing lines + GYR overlay. Supporting
controls: version link, recorder-destination counter + flags menu, start spot,
custom waypoint, hint decoder, hotkeys pop-out cheat sheet, "show/run custom"
(user-configurable: show images / run local executables or URLs — **security-
relevant, see `contracts.md`**), save, FQ/SQ toggle, legend, item-progress bar.

**GYR convention** (used throughout): green = reachable now, yellow = reachable
but may not exist (mixed-quest ambiguity), red = not reachable.

### 4.6 Dungeon tracker (10 tabs: 1–9 + "S" summary)
8×8 room grid, 7×8 horizontal + 8×7 vertical doors. Doors: 5 states (gray
unknown / green can-go / red can't-go / yellow maybe / purple maybe-variant).
Each room independently tracks 4 aspects:
- **RoomType** (34 values — see reference `DungeonRoomState.fs:231-272` for the
  full enumeration: entrance-from-N/E/S/W, transports 1–8, moats, chutes,
  turnstile, old-man-hint, bomb-upgrade, life-or-money, off-the-map, etc.)
- **Completedness** (done/todo, shown via brightness)
- **MonsterDetail** (32 values — every unique enemy/boss type in the game, plus
  Unmarked/Traps/Other/Other2)
- **FloorDropDetail** (9 values: Triforce, Heart, OtherKeyItem, BombPack, Key,
  FiveRupee, Map, Compass, Unmarked — each with a gotten/ungotten state)

Gestures: left-click = toggle complete (first click also sets entrance
direction; repeat rotates it), right-click = RoomType popup, scroll-up/
shift-left-click = MonsterDetail, scroll-down/shift-right-click =
FloorDropDetail, middle-click = toggle floor-drop-gotten or a yellow circle
marker. Click-and-drag painting (right-drag = off-the-map, left-drag =
unmarked, middle/shift-left-drag = mark-completed) with a grid overlay while
dragging. "GRAB" tool to cut/paste a map segment (fixes an offset mistake).
Vanilla-map overlay toggle (first/second quest) with compatibility hinting.
Per-dungeon inset (duplicate triforce/items/has-map), old-man count tracker,
NPC-hint color coding, bait icon (Hungry Goriya), mini-map hover preview,
summary-tab display modes (preview/detail/default).

### 4.7 Blockers
Up to 3 per dungeon, 8 kinds (Bow&Arrow, Recorder, Ladder, Key, Bait,
Money/Rupee, Bomb, Sword/Combat), each with a "maybe" gradient variant. A
"Specific Blockers" sub-menu marks exactly which of map/compass/triforce/
box1/box2/box3 a blocker gates, projecting tiny icons onto the Dungeon Item
Area. Reminders trigger when a blocking item is obtained.

### 4.8 Notes, Timeline
Free-text Notes box (stream-visible). Timeline posts items above minute
markers (1-second granularity, hover = split time), an overworld-spots-
remaining trend graph, and on-finish writes a completion-timeline image.
Reminder icons appear in a corner with a browsable log of past reminders.

### 4.9 Options (persisted, dozens of toggles)
Routing/highlighting toggles (DrawRoutes, HighlightNearby, ShowMagnifier,
Coords, door-inference, …), window/broadcast toggles (ShowBroadcastWindow +
size, blur effects, animation toggles), workflow toggles (SaveOnCompletion,
SnoopSeedAndFlags, HideTimer), speech toggles (ListenForSpeech,
RequirePTTForSpeech, PlaySoundWhenUseSpeech, PreferredVoice), per-category
voice+visual reminder toggles (7 categories — see § 4.10), 14
`HideOverworldTile_*` toggles, and display-convention toggles (e.g.
"BOARD" vs. "LEVEL" header wording).

### 4.10 Reminders (7 categories)
SwordHearts, RecorderPBSpotsAndBoomstickBook, HaveKeyLadder, Blockers,
DoorRepair, OverworldOverwrites, DungeonFeedback — each independently
toggleable for spoken (synthesized) and/or visual (timeline-corner icon + log)
delivery.

### 4.11 Hotkeys
User-editable hotkey file, 7 contexts (item boxes, overworld tiles, blockers,
dungeon rooms, TakeAny menu, TakeThis menu, Global — global keys must be
unique across contexts, others may reuse keys). Context-aware smart behaviors
(cycle red→green→purple, shop add/remove/replace, toggle-empty, etc.). v1.3
adds 4-directional cursor navigation across grids, per-action keys mapped to
left/middle/right-click and scroll-up/down, one modifier key, dungeon-tab
switching, and a "double-press" gesture with distinct semantics from a single
press for certain blocker/triforce/item actions.

### 4.12 Speech
- **Synthesis**: spoken reminders, selectable installed voice.
- **Recognition**: wake phrase ("tracker set") + ~35 recognized phrases to mark
  the currently-hovered overworld tile by voice. Must be enabled at startup
  (not toggleable mid-session in the reference app).

### 4.13 Extra windows
- **Broadcast window** — separate, non-interactive, square-ish window for OBS
  capture; auto-switches between overworld/dungeon view based on mouse
  position; fixed widths (768/512/256) for crisp integer-scaled capture;
  remembers its screen position.
- **Pop-out windows** — Spot Summary, Remaining Items, Inventory as small,
  movable, non-resizable always-on-top windows; positions persisted.
- **Hotkey cheat sheet** pop-out (persisted, right-click resets).
- **Draw layer** — arbitrary user icons overlaid on the tracker (from a
  user-provided `ExtraIcons/` folder).
- **User custom checklist** — a user-provided background image + labeled
  checkboxes, optionally logging to the timeline; config via a small JSON file.
- **Gamepad support** — controller input for tracker gestures (Windows-only in
  the reference app via `SharpDX.DirectInput`; macOS equivalent is the
  `GameController` framework — see `stack.md`).

## 5. Save / persistence model (see `data-model.md` for the exact schema)

JSON, hand-serialized, stored **next to the app binary** (not a system data
directory) in the reference app. Three save types: autosave (~every minute,
overwritten), manual save (timestamped file), and finished/completion save
(timestamped, optional auto-trigger on beating Ganon+Zelda). A **separate**
JSON file holds options/settings, independent of save state.

## 6. Open questions / UNKNOWNs (carried forward, not silently resolved)

- **Save-file compatibility decision** — should `z-tracker-mac` read/write the
  *same* JSON schema as `Zelda1RandoTools` (enables import of existing saves,
  but couples this project to a schema it doesn't control) or its own new
  schema inspired by it (full design freedom, no import path)? **Not decided.**
  Recommend resolving this explicitly before `data-model.md`'s schema is
  implemented, not assumed here.
- **Overworld routing algorithm** — described at a feature level (§ 4.4) but
  the exact rule-by-rule logic (Lost Woods/Lost Hills topology, any-road warp
  graph) lives in `OverworldRouting.fs`/`OverworldData.fs` and was not
  transcribed rule-by-rule. Needed before that feature can be implemented.
- **Hint-decoding tables** ("Aquamentus Awaits" → location halos) — mapping
  logic exists in code (`GetLevelHint`-style) but wasn't fully extracted.
- **Sprite atlas slicing offsets** — the source PNG atlases are identified
  (§ per `docs/decisions/0001-...md`), but exact per-icon pixel offsets live in
  `Graphics.fs` and weren't enumerated. Needed for pixel-perfect icon slicing.
- **Per-dungeon `DungeonMaps` save sub-schema** and **options-file exact
  filename** — top-level shape is known (`data-model.md`); field-by-field
  detail lives in `DungeonSaveAndLoad.fs` / `TrackerModelOptions.fs` and
  wasn't fully transcribed.
- **Whether v1.3.1 has ever been run/tested on macOS via Avalonia** — inferred
  to be no (unshipped, EOL toolchain) from project files and docs, not
  empirically tested by launching it.
- **Retina/high-DPI asset strategy** — reuse original sprite sheets as-is
  (crisp at their native small size, per the original's own integer-scaling
  design) vs. eventually redraw at higher resolution. Not decided; not
  blocking initial work (see ADR 0001).

## Update-this-doc-when

Update this file whenever a parity feature above is implemented (cross-reference
the task that implemented it) or whenever a deliberate parity gap is decided
(record as an ADR, then reflect the descope here so this stays the accurate
checklist rather than an aspirational one).
