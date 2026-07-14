# Domain — z-tracker-mac (feature-parity inventory)

**Status:** grounded in the reference app (`Zelda1RandoTools`), not this repo's
(nonexistent) code. This is the **acceptance-criteria baseline** for "feature-by-
feature, near pixel-perfect clone" — every item below is something the clone is
expected to eventually replicate, unless a future ADR explicitly descopes it.

**Verification:** produced by a dedicated inventory pass over
`Zelda1RandoTools`'s `doc/*.md` and F# source (`Z1R_Tracker/`), 2026-07-02,
**plus** two visual passes the same day: (1) the ~100 screenshots already
committed in `Zelda1RandoTools/doc/screenshots/` (referenced from the doc
`.md` files), and (2) live screenshots of the actual running v1.3.1 app in a
Windows 11 ARM VM, for the one screen the repo's own screenshots don't cover
(the startup screen — `quick-start.md`'s screenshot is the *main* window,
taken after startup). The live-VM pass corrected a factual error in an
earlier draft of § 4.1 (window size and shape are independent settings, not
one combined preset list) — see § 4.1 for what changed. File/line citations
below point into that repo. Re-verify against `Zelda1RandoTools` directly if
this ever seems stale — it is a pinned fork
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

**Verified against the running reference app** (v1.3.1, screenshotted live in
a Windows 11 ARM VM, 2026-07-02) in addition to the doc/source pass — this
corrected two details the text-only inventory pass got wrong or missed. Also
cross-checked against `doc/screenshots/size-and-shape-options.png`.

- Heart Shuffle toggle, Hide Dungeon Numbers toggle — **implemented, T-003**
  (`TrackerCore.TrackerModel.heartShuffle`/`.hideDungeonNumbers`,
  `StartupView`). Toggling their effect elsewhere (dungeon pre-fill / numeral
  hiding) is not implemented yet — only the startup-screen state capture is.
- 4 overworld-quest start buttons — **implemented, T-003** — confirmed
  on-screen labels: "Start: First Quest Overworld", "Start: Second Quest
  Overworld", "Start: Mixed - First Quest Overworld", "Start: Mixed - Second
  Quest Overworld (or randomized quest)" (spot counts: 1Q=73, 2Q=80, Mixed=93,
  "UQ"=128 — the spot-count behavior itself is not implemented yet, only quest
  selection and navigation to the (placeholder) main view)
- Alternative overworld map mode: blank 16×8 grid, fully-revealed load, or
  hidden-until-clicked load — **not implemented** (see `tasks/T-003.md` "Out
  of scope" — niche, `other.md`-scope feature, deferred)
- "- OR -" divider, then "Start: from a previously saved state" (restores
  HS/HDN/OW from the save) — **UI present but disabled, T-003**; needs
  save-file persistence (`data-model.md` § 4 compatibility decision) before
  it can actually do anything
- A random tip/factoid box — **implemented, T-003**, but backed by
  `TrackerCore.TipProvider.placeholderTips`, an explicitly-labeled small
  illustrative subset (3 tips), not the exhaustive original list — see
  `tasks/T-003.md` "Out of scope"
- Below that: **"Settings (most can be changed later, using 'Options...'
  button above timeline)"** — a live options panel embedded directly on the
  startup screen, in 3 columns — **fully implemented, T-004 + T-005**
  (`TrackerCore.TrackerOptions`, `ZTrackerMac.SettingsPanelView`). Confirmed
  by both screenshot and by reading `Z1R_WPF/OptionsMenu.fs` directly — the
  single WPF component the reference app shares between the startup screen
  and the main window's "Options…" button (same code, two call sites), which
  is what let every remaining "unconfirmed placement" item below be resolved
  for real rather than guessed:
  - **Overworld settings:** Draw routes, Show screen scrolls, Highlight
    nearby, Show magnifier, Shops before dungeons — implemented. "More
    settings…" opens a real popover (T-005) listing the 12 overworld tile
    kinds that can be hidden (`OverworldHiddenTileKind`) plus "Hide
    no-longer-relevant shop items" and "Always hide meat shops" — matches
    `TrackerModelOptions.OverworldTilesToHide` exactly (14 fields total).
    **Dungeon settings:** BOARD instead of LEVEL, Show basement info, Do door
    inference, Book for Helpful Hints, Left-drag auto-inverts, **Default to
    NonDescript, Dungeon 'sunglasses'** (`GiveDungeonTrackerSunglasses` —
    confirmed to belong here, added in T-005) — all implemented.
  - **Reminders:** a volume slider, "Disable all," and a Voice/Visual
    two-column checkbox matrix for the 8 reminder categories (§ 4.10):
    Dungeon feedback, Sword hearts, Coast Item, Recorder/PB/Boomstick, Have
    magic key/ladder, Blockers, Door Repair Count, Overworld overwrites — all
    implemented with correct per-category defaults (all `true` except
    Recorder/PB/Boomstick). "Change voice…" opens a real popover (T-005)
    listing installed voices via `AVSpeechSynthesisVoice.speechVoices()`,
    with Test/Choose actions — matches the reference app's own
    `voice.GetInstalledVoices()` UI, including the same >1-voice gate before
    showing the button.
  - **Other:** Animate tile changes, Animate shop highlights, Save on
    completion, Snoop for seed&flags, Display seed&flags, Listen for speech
    (confirmed startup-only — cannot be toggled on later, matches the
    original inventory note), Confirmation sound, a Broadcast window
    radio-group (**Full size broadcast / 2/3 size broadcast / 1/3 size
    broadcast** — the user-facing labels for the 768/512/256 px widths in
    § 4.13), Include overworld magnifier, Mouse magnifier window, **Hide
    timer** (confirmed to belong here, added in T-005) — all implemented.
  - **Resolved, confirmed excluded** (T-005 — checked `OptionsMenu.fs`
    directly rather than leaving as "unconfirmed"): `RequirePTTForSpeech` is
    dead code in the reference app itself — its checkbox is commented out
    with the note "not (yet) a fully supported feature, so don't publish it
    on the options menu" (`OptionsMenu.fs:400-419`). `UseBlurEffects` does
    not appear anywhere in `OptionsMenu.fs` at all — it's controlled
    elsewhere in the reference app, not this component, so correctly absent
    from this panel. `SmallerAppWindow`/`ShorterAppWindow`/
    `SmallerAppWindowScaleFactor` belong to the separate Size & Shape option
    (not this embedded panel) and are moot for this project per ADR 0003
    (responsive layout).
- **Window size vs. window shape are two independent settings, not one
  combined preset list** (corrected from an earlier draft of this doc, which
  conflated them): **Window Size** = 4/3 size (Largest) / Default / 5/6 size /
  2/3 size (Smallest); **Window Shape** = Tall (default) or Square. Square
  "auto-swaps between Overworld and Dungeon focus, based on your mouse" and
  disables the overworld magnifier, broadcast window, and Draw/UCC buttons.
  **Critically: "this option only affects the main application; the startup
  options screen is always 'Tall'"** — i.e., the reference app's own startup
  screen never varies its layout at all, regardless of the user's size/shape
  settings. **Intentionally NOT cloned** — `z-tracker-mac`'s startup screen
  (and main window) is responsive and reflows instead of using fixed
  presets/a fixed shape; see
  `docs/decisions/0003-responsive-layout-not-fixed-presets.md`. (The
  broadcast window, § 4.13, is the one exception and does keep fixed sizing.)
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
`OverworldRouting.fs`/`OverworldData.fs`. **Algorithm fully ported (T-009,
T-010):** static adjacency graph, dynamic layer (screen-scroll variants,
recorder-warp/any-road edges), and the `findAllBestPaths` priority-queue
search all live in `TrackerCore.OverworldRoutingGraph`, verified with
known-route regression tests.

**UI: minimal slice shipped (T-011), full fidelity deferred to T-012.**
Hovering an overworld tile now draws real route lines to nearby unmarked
screens and highlights the cheapest ones (bold) plus the next-cheapest
(pale) — `OverworldMapView`'s `OverworldRouteLinesOverlay` and
`TrackerCore.OverworldRoutingGraph.routeHighlight(...)`. Reading
`OverworldRouteDrawing.fs` in full surfaced that the reference app's real
feature goes further in two ways this task deliberately does not attempt,
both tracked as `T-012`:
1. **True GYR** (green="accessible", yellow="sometimes empty",
   red="inaccessible") requires `TrackerModel.fs`'s `MapStateSummary`/
   `recomputeMapStateSummary` — dungeon completion, triforce count,
   item possession, sword-cave/armos progress — none of which exists in
   `z-tracker-mac` yet. This task's highlight uses a single "reachable,
   currently-unmarked" semantic instead (real, correct for what it
   computes; not a stand-in for red/yellow).
2. **The destination-picker menu** (pick a specific tile/shop/dungeon/cave
   target) isn't built — the current behavior is always "show routes to
   everywhere nearby," matching the reference's own passive hover mode but
   not its explicit-destination mode.
`ladder`/`raft`/mirror-overworld are also placeholder `true`/`true`/`false`
constants in `OverworldMapView` (no item-possession or mirror-overworld
state exists yet to wire to instead) — `RoutesCanScreenScroll` *is* wired to
the real `TrackerOptions.showScreenScrolls` toggle, since that one already
existed. See § 6.

### 4.5 Overworld map (16×8 grid, 36 tile-mark types)

**Count corrected (T-007):** this doc previously said "38 tile-mark types,"
an unverified number. Reading `MapSquareChoiceDomainHelper` directly
(`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/TrackerModel.fs:310-354`) — the
reference app's own authoritative tile-index enumeration — confirms exactly
**36** (indices 0...35, `DUNGEON_1` through `DARK_X`).

**Icon source corrected (bugfix, post-T-007):** T-007 bundled
`s_icon_overworld_strip39.png` and built the icon-index mapping around it,
reasoning that its 39 images (3 more than the 36 tile-mark types) were
"unaccounted for — unused/reserved, most likely." That reasoning was
backwards: the file *itself* is unused. Reading `Z1R_WPF/Graphics.fs:767`
shows it loaded into a variable named `zhMapIcons`, and a repo-wide search
confirms that variable is never referenced anywhere else — it's dead code,
a leftover from the ZHelper tool that inspired Z-Tracker before its
overworld tiles were redesigned with smaller icons
(`Zelda1RandoTools/doc/about.md`: *"Overworld tiles in particular required
redesigning new, slimmer icons, rather than the full-tile icons I had
copied from ZHelper"*). The real icon system, confirmed by reading
`theInteriorBmpTable`'s construction (`Graphics.fs:850-945`) and its
consumers (`OverworldMapTileCustomization.fs`) and verified icon-by-icon
against the actual strip pixels: a small 5×9 icon centered within the
16×11 tile (not a full-tile image), drawn from `ow_icons5x9.png` (14 icons)
for sword caves/secrets/door-repair/money-game/letter/armos/hint-shop/
take-any/potion-shop, `icons3x7.png` (8 icons) composited on an orange
background for shops, and a painted digit on a colored background for
dungeons/any-roads. See `OverworldTileMark.iconSource`'s doc comment for
the full grounding.

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

**Implementation status (T-006/T-007/T-008, icon source bugfixed post-T-007):**
the tile-mark data model (`TrackerCore.OverworldTileMark`, `OverworldGrid`,
16×8), the icon-source mapping (`OverworldTileMark.iconSource`, grounded
exactly in `MapSquareChoiceDomainHelper` and `theInteriorBmpTable`), **real
sprite-icon rendering** (`ow_icons5x9.png` + `icons3x7.png`, the reference
app's actual interior-icon sources — not the dead `s_icon_overworld_strip39.png`
ZHelper leftover T-007 originally used — bundled as SPM resources with
attribution in `/NOTICE.md`, cropped per-tile via `OverworldInteriorIconAtlas`/
`OverworldShopIconAtlas`), **real terrain background art per quest**
(`s_map_overworld_vanilla_strip8.png`, cropped via `OverworldBackgroundAtlas`,
quest-indexed via `OverworldQuest.referenceAppIndex` — grounded exactly in
`OverworldData.fs`'s `OWQuest.AsInt`), and the core "left-click unmarked →
mark dark" / "right-click (or click-when-dark) → selection menu" gestures
are **implemented** (`ZTrackerMac.OverworldMapView`) — verified visually:
the rendered map is recognizably the actual Zelda 1 First Quest overworld
(forests, lakes, the graveyard area all correctly placed, no gaps or
misalignment), and every one of the 36 tile-mark icons was individually
verified against the real reference sprite strips by temporarily seeding
all 36 marks and screenshotting, pixel-matched against direct crops of
`ow_icons5x9.png`/`icons3x7.png`. **Not yet implemented:** the "darkened
once obtained" variant (needs the item/dungeon state layer, `T-013`/`T-014`
— see § 6), the two-item shop display, HDN-mode's lettered dungeon variant
(`T-016`), middle-click circling, shift-variants, the take-any pie-menu
accelerator, hover magnifier/routing lines/GYR overlay, and all the
supporting controls listed above (version link, recorder-destination
counter, hint decoder, "show/run custom", save, FQ/SQ, legend,
item-progress bar). The `BLANK` quest / "alternative overworld map" custom
mode remains out of scope, as originally deferred.

**Layout constants resolved (T-006), background art resolved (T-008):** the
base overworld tile is 16×11px, rendered at 3x scale by default
(`OMTW = 48. // 16*3`, `Graphics.fs:358`) — this was an open question in an
earlier draft of this doc ("Layout.fs / OMTW numeric constants... not fully
dumped"). The reference app's map background art comes from
`s_map_overworld_vanilla_strip8.png` (1280×88px, 5 sections of 256×88px —
the first 4 are the real quest layouts, the 5th is unused/blank), read via
`Graphics.fs`'s `overworldMapBMPs` pixel-indexing math and confirmed by
direct visual inspection of the source file (not just arithmetic).

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
PlaySoundWhenUseSpeech, PreferredVoice — **`RequirePTTForSpeech` listed here
in an earlier draft, but it's actually dead/commented-out code in the
reference app's UI, never exposed to users**, see § 4.1's "resolved,
confirmed excluded" note), per-category voice+visual reminder toggles (8
categories, not 7 — see § 4.10), 14 `HideOverworldTile_*` toggles (the "More
settings…" panel, § 4.1), and display-convention toggles (e.g. "BOARD" vs.
"LEVEL" header wording).

### 4.10 Reminders (8 categories + 1 special case)

**Corrected** — an earlier draft of this doc said "7 categories" and omitted
"Coast Item"; verified directly against the `ReminderCategory` enum
(`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/TrackerModel.fs:6-15`), not
re-derived from memory of the first inventory pass.

The 8 user-toggleable categories, each independently toggleable for spoken
(synthesized) and/or visual (timeline-corner icon + log) delivery — display
names per the enum's own `DisplayName`: Dungeon feedback, Sword hearts,
Coast Item, Recorder/PB/Boomstick, Have magic key/ladder, Blockers, Door
Repair Count, Overworld overwrites.

Plus a 9th enum case, `Asterisk` ("Error beeps"), which is **not** confirmed
to be a user-facing toggle in the settings panel (no evidence yet either way)
— flagged as **UNKNOWN — needs human confirmation** rather than assumed
either in or out of scope for `T-004`'s reminder-matrix UI.

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
  remembers its screen position. **This fixed sizing IS cloned** (unlike the
  main window, § 4.1) — OBS window capture wants a stable size; see
  `docs/decisions/0003-responsive-layout-not-fixed-presets.md`.
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
- **Overworld routing algorithm — fully ported (T-009, T-010); UI is a
  minimal slice (T-011), full fidelity blocked on the item/dungeon state
  layer (T-012).** The full system (`OverworldRouting.fs`) is a hand-built
  ~130-edge adjacency graph (most screens one vertex, ~12 split into
  half-screen vertices for narrow passages) with asymmetric Lost Woods/Lost
  Hills traps and ladder/raft-conditional crossings, feeding a
  priority-queue multi-path breadth-first search. The **static** layer
  (T-009) is transcribed edge-for-edge in `TrackerCore.OverworldRoutingGraph`,
  cross-checked against the F# source by call-count comparison and validated
  by porting the reference app's own 128-screen consistency sanity check as a
  real test. The **dynamic** layer and the search itself (T-010) — screen-
  scroll variants for mirrored/normal overworld (`staticMirrorScreenScrolls`/
  `staticNormalScreenScrolls`), recorder-warp/any-road edges
  (`populateDynamic`), vertex disambiguation (`convertToCanonicalVertex`,
  including its upstream "TODO check" cases, transcribed as-is rather than
  second-guessed), and `findAllBestPaths`'s tie-accumulating priority-queue
  search — are all ported and covered by known-route regression tests (e.g.
  a hand-verified Lost Woods dead-end: the only path into `(0,6)` costs
  exactly 8, since that screen has no other connection in the graph).
  **T-011** wired this into `OverworldMapView`: hovering a screen draws real
  route lines (via `OverworldRouteHighlight`'s ported `drawPathsImpl` logic)
  and highlights the nearest unmarked screens, using
  `GeometryReader`-relative coordinates instead of the reference's
  fixed-pixel `Canvas`, since this app is responsive/reflowing
  (`decisions/0003`). Two things are deliberately not attempted: true GYR's
  red/yellow distinctions (needs `MapStateSummary`-equivalent item/dungeon
  state, which doesn't exist at all in `z-tracker-mac` yet) and the
  destination-picker menu. **Update (T-014):** `ladder`/`raft` are now wired
  to live `PlayerComputedStateSummary` state; only `mirror`
  (`MirrorOverworld`) remains a placeholder constant in `OverworldMapView`
  (its option/save wiring is T-015; `RoutesCanScreenScroll` was already
  real). True GYR red/yellow and the destination-picker menu are still T-015.
  See the next item for the full plan to close this gap.
- **Player state layer (item possession, dungeon completion/triforce,
  progress) — scoped into a 7-stage plan (`T-012`-`T-018`); T-012 done, rest
  not started.** Discovered as a hard blocker for true GYR while scoping
  `T-011`; a full read-through of `TrackerModel.fs`'s player-state
  subsystem (1878 lines) sized and staged it, mirroring how the routing
  algorithm split into `T-009`/`T-010`:
  - **T-012 — done.** `StartingItemsAndExtras` + `PlayerProgressAndTakeAnyHearts`
    (`TrackerModel.fs:492-570`) ported field-for-field to `TrackerCore` as
    `@Observable` classes, defaults verified against
    `SaveAndLoad.fs:56-151`. Both owned by `TrackerModel`
    (`startingItemsAndExtras`, `playerProgress`) and surfaced via a
    bare-bones, explicitly-labeled debug panel in the main tracker view (a
    real item-tracker UI is a later task's concern, once `T-013`/`T-014`
    give this state something to compute against). These two data bags were
    genuinely dependency-free, unlike `T-009`'s static graph — confirmed
    during scoping.
  - **T-013 — done.** `Box`/`Dungeon`/`DungeonTrackerInstance` core
    (`TrackerModel.fs:582-837`) ported to `TrackerCore` (`DungeonBox.swift`,
    `DungeonTracker.swift`), DEFAULT mode only: `PlayerHas` tri-state
    (raw values pinned to `NO=0/YES=1/SKIPPED=2`), `Box`
    (item-slot + possession + `isDone`/`isEmptyRedBox`), the nine
    `Dungeon`s with the quest-dependent shared `finalBoxOf1Or4` third box
    (base counts `[2,2,2,2,2,2,2,3,2]` transcribed exactly from
    `makeDungeons()`; `allBoxes()` = 23), `isComplete`, `toggleTriforce`,
    `getTriforceHaves()`, and `allBoxProgress`. Confirmed during scoping and
    in the port: `armosBox`/`ladderBox`/`sword2Box` are plain `.skipped`
    `Box` instances, **not** a distinct subsystem. Owned by `TrackerModel`
    as `dungeonTracker`. **Three deliberate parity simplifications, none
    behavior-changing:** (1) `Box`'s `Cell`/`ChoiceDomain` cross-box
    item-max-use machinery is *not* ported — `cellCurrent` is a plain item
    index (`-1` empty, `0…14`) matching `Cell.Current()`, since the
    completion model needs only "is a value known"; the overworld's
    `OverworldGrid` set the same precedent, and the item-picker cycling that
    actually needs `ChoiceDomain` lands with its first consumer (T-014/T-015).
    (2) `@Observable` replaces every F# `Event<_>`/`LastChangedTime`
    publisher. (3) `isComplete` is a plain computed property, not the F#
    cached/reentrancy-guarded member — the guard existed only because
    reading it fired an event that could recurse; a getter can't. No UI was
    added (unlike T-012's debug panel) — none is in T-013's acceptance
    criteria; the real item-tracker UI is T-015. Still deferred to T-016:
    `StairKind`/`BoxOwner`/`CurrentlyHasBasementStair`, HDN mode (guarded
    with a precondition, not silently wrong), `Color`/`LabelChar`. Deferred
    to T-014/T-015: `PlayerCanSeeMapOfThisDungeon` (needs book/atlas state),
    `HasBeenLocated` (needs the overworld map-square domain).
  - **T-014 — done.** `PlayerComputedStateSummary` derivation
    (`TrackerModel.fs:841-958`) ported as an immutable 16-field value struct
    (`PlayerComputedStateSummary.swift`) plus a structure-preserving
    `compute(...)` that scans `dungeonTracker.allBoxes()` for `.yes` cells by
    `ITEMS.*` index, then layers in progress flags, starting items, the two
    standalone-box (`ladderBox`→`haveCoastItem`, `sword2Box`→
    `haveWhiteSwordItem`) done-checks, and hearts. `ITEMS` index constants
    (`Items.swift`) ported value-for-value; `Box.itemCount` now sources
    `ITEMS.count`. Surfaced as a computed `TrackerModel.playerComputed-
    StateSummary` (re-derives via `@Observable`, replacing the F# mutable
    global + `recompute()` + `LastChangedTime`/event plumbing). **Grounding
    finding:** the recompute branches on **only one** seed-option flag,
    `IsWSMSReplacedByBU` (added to `TrackerModel`); the task's "three-flag
    (book/atlas/WSMS)" phrasing overstates the actual code —
    `IsCurrentlyBook`/`IsBookAnAtlas` gate `PlayerHasTheBook` /
    `PlayerCanSeeMapOfThisDungeon`, which are deferred with their own
    consumers, so those two flags are added when those land, not here. The
    White-Sword/Magical-Sword asymmetry is preserved exactly: the *starting-
    item* sword always counts (real sword), the *box/progress* sword is
    suppressed under WSMS-as-BU (`:911`/`:924`). Closes T-011's placeholder
    gap for ladder/raft: `OverworldMapView` now routes on
    `playerState.haveLadder`/`.haveRaft` — so a fresh game correctly routes
    *without* ladder/raft (previously hardcoded `true`), matching the
    reference's `OverworldRouteDrawing`. `MirrorOverworld` stays a
    placeholder (its option/save wiring is T-015).
  - **T-015 — split into T-015.1…T-015.6.** A grounded scoping read
    (2026-07-13) found T-015's premise ("mostly overworld/routing work
    `z-tracker-mac` already has") was inaccurate: the `owInstance`
    terrain-capability predicates (`OverworldData.OverworldInstance`,
    `OverworldData.fs:273-339`) and the shop second-item extra-data store
    (`TrackerModel.fs:996-1011`) were **never** ported by T-006–T-010. So it
    was split into six ordered sub-tasks, mirroring the T-009/T-010 routing
    split: **T-015.1** terrain masks + `OverworldInstance` (foundation,
    pure data); **T-015.2** shop extra-data store + `OverworldTileMark`
    raw-index bridge; **T-015.3** `recomputeMapStateSummary` +
    `MapStateSummary` (`:1013-1143`) → `owGettableLocations`/
    `owRouteworthySpots` + the 8 discovery flags; **T-015.4** true GYR
    (green/yellow/red + cyan) from `doComputedDrawing`
    (`OverworldRouteDrawing.fs:40-70`); **T-015.5** live mirror/warp/any-road
    placeholder wiring; **T-015.6** the destination picker
    (`LinkRouting.fs:15-235`).
    - **T-015.1 — done.** `OverworldInstance.swift`: all ~13 literal 16×8
      terrain masks transcribed verbatim + 3 derived masks
      (`mixedQuestAlwaysEmpty`/`firstQuestOnly`/`secondQuestOnly`) computed
      as the reference does, and the 11 predicates (`alwaysEmpty`,
      `ladderable`, `hasArmos`, `raftable`, `whistleable`,
      `powerBraceletable`, `gravePushable`, `burnable`, `bombable`,
      `nothingable`, `sometimesEmpty`) with the MIXED=1Q-OR-2Q rules.
      `OWQuest.BLANK` stays deferred with the custom-overworld mode.
      Transcription verified by per-mask `X`-count pins against
      `OverworldData.fs` (8 tests).
    - **T-015.2 — done.** `OverworldTileMarkRawIndex.swift`: the raw-int
      bridge between the typed `OverworldTileMark` and the reference's
      `MapSquareChoiceDomainHelper` 0…35 numbering (`rawIndex`/`fromRawIndex`
      explicit per case, `isItem`/`toItem`/`shopExtraDataKey`(=16)/
      `numShopItems`(=8)/`maxRawIndex`(=35, verified: the domain has exactly
      36 entries). Plus the per-tile extra-data store on `OverworldGrid`
      (`extraData`/`setExtraData`, 36 keys/tile = `DARK_X+1`) ported from
      `overworldMapExtraData` (`TrackerModel.fs:996-1011`) — the shop
      second-item / potion-letter / un-revealed toggles the recompute reads.
      8 tests pin the full numbering + round-trips.
    - **T-015.3 — done.** `MapStateSummary.swift`: the overworld map-state
      derivation, a structure-preserving port of `recomputeMapStateSummary`
      (`TrackerModel.fs:1032-1143`). Iterates every non-always-empty screen,
      classifies by the mark's raw index, and produces
      `owGettableLocations` (the red-GYR input), `owRouteworthySpots`, the
      dungeon/any-road/sword/armos locations, `owSpotsRemain`,
      `owWhistleSpotsRemain`, `owPowerBraceletSpotsRemain`, the
      first/second-quest-only interesting-mark grids, and the 8
      shop/cave-discovery flags — folded into one immutable value struct
      (`ScreenBoolGrid` for the 16×8 bool arrays). `@Observable`-computed on
      demand, replacing the reference's mutable global + `recompute()` +
      `EventingBool`s. All external globals (grid, instance, dungeon tracker,
      player summary, progress, and the `drawRoutes`/`routesCanScreenScroll`/
      `mirrorOverworld` flags the coast-island special case reads) are passed
      explicitly; `mirrorOverworld` has no live source until T-015.5.
      Verified by 12 scenario tests including pinned empty-first-quest counts
      (owSpotsRemain 73, gettable/routeworthy 28) that exercise the terrain
      masks + raw-index bridge + recompute end-to-end.
    - **T-015.4 — done.** True GYR rendering. `OverworldRouteTint.swift` is
      the pure green/yellow/red cascade ported from `doComputedDrawing`
      (`OverworldRouteDrawing.fs:44-63`): marked dungeon 1–8 → green; else
      not-gettable → red; else `sometimesEmpty` → yellow; else green. Wired
      into `OverworldMapView` via a `mapState: MapStateSummary` parameter
      (computed reactively in `MainTrackerPlaceholderView`), replacing
      T-011's flat single-color "reachable" overlay; bold/pale stays the
      `isBold` reachability axis rendered as opacity. **The cyan override for
      the selected route target is deferred to T-015.6** (there's no selected
      target until the picker exists). 6 cascade tests. This is the visible
      GYR payoff the whole T-012→T-015.3 stack was building toward.
    - **T-015.5 — done (narrowed).** Any-road warp destinations wired:
      `OverworldMapView` now feeds live `mapState.anyRoadLocations` to
      `dynamicGraph(anyRoads:)` (was empty), so 2+ marked any-roads warp
      between each other (cost 4) in hover routing — the graph machinery was
      already ported (T-010), just fed empty. **Grounding-driven re-scope:**
      recorder-warp destinations fold into **T-018** (derived in the
      reminders/orchestration path, needing recorder options + HDN + vanilla
      dungeon locations, none ported), and `MirrorOverworld` split to
      **T-015.7** (a full display-flip feature, not just the routing
      `isMirror` flag). Warp-line dashed/skipped styling deferred with those
      (needs warp-vs-walk edge metadata the graph doesn't carry).
  - **T-016 — split into T-016.1…T-016.3.** Hide Dungeon Numbers is a large
    orthogonal mode; like T-015 it splits into a model core (portable now)
    and UI/rendering pieces needing a dungeon-tracker room-grid UI that
    doesn't exist yet.
    - **T-016.1 — done.** HDN model core in `DungeonTracker.swift`: the
      `.hideDungeonNumbers` kind is no longer guarded off; HDN box counts
      (dungeons 1–8 get 3, dungeon 9 gets 2; `allBoxes()` = 29; no shared
      `finalBoxOf1Or4`), the `isComplete` HDN branch (triforce + 3-done OR
      2-done when `labelChar` is a quest-dependent two-boxer, whitelists
      `"123567"` 2nd quest / `"234567"` 1st), per-dungeon `color`/`labelChar`
      state, and `getTriforceHaves(hdnStartingTriforcePieces:)` HDN indexing
      (identified `labelChar`→piece + HDN starting pieces). Transcribed from
      `TrackerModel.fs:682-836`'s HDN branches; 9 tests, DEFAULT paths
      unchanged. `TrackerModel` still constructs `.default` — wiring the
      `hideDungeonNumbers` toggle to build an HDN instance rides with T-016.3.
    - **T-016.2** — `StairKind`/`BoxOwner`/`CurrentlyHasBasementStair`
      (`:587-632`) basement-stair metadata, deferred until the dungeon-room-
      grid UI exists.
    - **T-016.3** — HDN labeling UI + overworld lettered-dungeon rendering
      (`Color`/`LabelChar` UI; `OverworldTileMark.iconSource`'s HDN variant),
      deferred until a dungeon-tracker UI host exists.
  - **T-017** — Dungeon blockers ("why I left this dungeon" reminders,
    `TrackerModel.fs:1147-1273`) — reads player-state, doesn't feed back
    into it, cleanly deferrable.
  - **T-018** — Reminders/announcements/Triforce-and-Go orchestration
    (`TrackerModel.fs:1439-1750`, ~310 lines) — the top-of-stack consumer
    of everything else; includes a real architecture decision (reactive
    `@Observable` vs. a literal `ITrackerEvents`-delegate port) flagged for
    evaluation when that task starts, not decided here.
  Also confirmed *not* part of this subsystem despite a similar name:
  `DungeonData.fs` (290 lines) is dungeon-room-shape ASCII grids + flavor
  tips for a future dungeon-map-drawing UI — unrelated to player state.
- **Hint-decoding tables** ("Aquamentus Awaits" → location halos) — mapping
  logic exists in code (`GetLevelHint`-style) but wasn't fully extracted.
- **Sprite atlas slicing offsets — resolved (T-006/T-007/T-008), icon
  *source* corrected post-T-007 (bugfix).** Base tile size is 16×11px at 1x,
  rendered at 3x by default (`OMTW = 48. // 16*3`, `Graphics.fs:358`). The
  real interior-icon sources are `ow_icons5x9.png` (70×9px = 14 icons of
  5×9px each) and `icons3x7.png` (24×7px = 8 icons of 3×7px each), composited
  centered within the 16×11 tile — **not** a single flat strip of 16×11
  full-tile icons as T-007 originally assumed (`s_icon_overworld_strip39.png`
  turned out to be dead ZHelper-era code the reference app never draws with;
  see § 4.5). The index-to-tile-mark-kind mapping is extracted and grounded
  in `MapSquareChoiceDomainHelper` (`TrackerModel.fs:310-354`) and
  `theInteriorBmpTable` (`Graphics.fs:850-945`) — implemented as
  `OverworldTileMark.iconSource`. The overworld map's *background* art
  (terrain, `s_map_overworld_vanilla_strip8.png`) was resolved separately in
  T-008 and is unaffected by this correction.
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
