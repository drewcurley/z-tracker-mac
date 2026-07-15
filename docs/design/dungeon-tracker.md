# Dungeon Tracker — Scoping & Implementation Plan

**Status:** DRAFT for review (no code yet)
**Date:** 2026-07-15
**Scope owner:** Drew Curley (single-operator review per `playbook/AGENTS.md`)
**Grounded in:** 5 parallel research passes over the F# reference
(`Zelda1RandoTools/Z1R_Tracker`), all `file:line`-cited; see the transcript.

---

## 1. Goal & scope

Build the **middle band** of the tracker — everything from below the item/overworld
area down to (but not including) the timeline — to reach parity with the reference.
Three deliverables:

1. **Dungeon room-map grid** — per dungeon, an **8×8 grid of rooms**. Each cell is
   *one room*; the user marks its **room type**, **monster**, **floor item**, and
   the **doors** connecting it to neighbours. Plus transport-stair pairing, room
   circling, old-man count, per-dungeon map/compass, vanilla FQ/SQ outline
   overlays, and a Summary tab.
2. **Blockers UI** — a view over the *already-built* blockers model.
3. **Notes** — a free-text notes box.

### Explicitly OUT of scope
- **Intra-room tile maps** (where a push-block sits *inside* one room). The
  reference doesn't do this either — a room is a single cell.
- **The drawing/stamp layer** (cut by the user).
- **The timeline** (item-acquisition-over-time) — the lower boundary; a separate
  later task.
- **Save/load** — pinned until broader parity (this feature is a prerequisite for
  a faithful save format, not the other way around).

### Kept as-is
The existing top-section 9-card dungeon widget (`DungeonCardView`: triforce, item
boxes, HDN label/colour, basement-stair glyph). The new room grid is **additional**
— in the reference the dungeon tab area holds *both* the room grid and a small
local item/triforce inset that mirrors the top card.

---

## 2. Reference data model (what a room is)

A room is five fields (`DungeonRoomState.fs:469-491`):

| Field | Type | Default |
|---|---|---|
| `isCompleted` | Bool | false |
| `roomType` | `RoomType` (~34) | `Unmarked` |
| `monsterDetail` | `MonsterDetail` (32) | `Unmarked` |
| `floorDropDetail` | `FloorDropDetail` (9) | `Unmarked` |
| `floorDropAppearsBright` | Bool | true |

Doors are **not** on the room — they're a separate per-dungeon structure:
`horizontalDoors[7][8]` + `verticalDoors[8][7]`, each a 5-state `DoorState`
(`Dungeon.fs:19-59`). Room-circling (`roomIsCircled[8][8]`) and the transport-pair
usage counter (`usedTransports[9]`) are also per-dungeon, outside the room state.

### RoomType (~34) — `DungeonRoomState.fs:230-272, 330-365`
`Unmarked`, `NonDescript`, `MaybePushBlock`, `ItemBasement`, `StaircaseToUnknown`,
`Transport1…8` (matched pairs), `Chevy`, `DoubleMoat`, `TopMoat`, `RightMoat`,
`CircleMoat`, `Tee`, `LavaMoat`, `VChute`, `HChute`, `Turnstile`, `OldManHint`,
`BombUpgrade`, `LifeOrMoney`, `HungryGoriyaMeatBlock`, `StartEnterFromE/W/N/S`,
`OffTheMap`, `Gannon`/`Zelda` (level-9 only).

- `IsOldMan` = OldManHint ∪ BombUpgrade ∪ HungryGoriyaMeatBlock ∪ LifeOrMoney →
  drives the Old-Man count.
- `StartEnterFrom*` cycles S→W→N→E on click.
- Transports come in numbered pairs; a third copy of a number is rejected.

### MonsterDetail (32) — `DungeonRoomState.fs:26-59, 129-162`
`Unmarked` + 31 markable. Display names differ from case names (e.g. internal
`Bow` shows **"Gohma"**; `BlueWizzrobe`→"Wizzrobe", `RedLynel`→"Lynel",
`BlueMoblin`→"Moblin"). **Wiki-verify** the ambiguous ones: `RupeeBoss`, `Other`,
`Other2`, `Traps`.

### FloorDropDetail (9) — `DungeonRoomState.fs:175-228`
`Unmarked`, `Triforce`, `Heart`, `OtherKeyItem`, `BombPack`, `Key`, `FiveRupee`,
`Map`, `Compass`.

### DoorState (5) — `Dungeon.fs:19-35`
`Unknown`(0, dim), `No`(1, red wall), `Yes`(2, green open), `Yellow`(3, "locked?"),
`Purple`(4, "shutter?"). No dedicated "bombable" — Yellow/Purple are generic
"other". Cycle order: Unknown→Yes→No→Yellow→Purple→Unknown.

---

## 3. Reference interactions (the rich part)

Per room cell (`DungeonUI.fs:1348-1472`):
- **Left-click**: first-ever click sets the entrance lobby; else marks
  `NonDescript`+complete, or toggles complete, or cycles the entrance arrow.
  Shift+left → Monster picker.
- **Right-click**: opens the **Room-Type picker** (7×5 modal grid). Shift+right →
  Floor-Drop picker.
- **Middle-click**: toggle floor-drop brightness (if a drop is marked) else toggle
  the room circle.
- **Wheel**: up → Monster picker, down → Floor-Drop picker.
- **Hover**: highlight the row + column; flash the overworld meat-shop locator for
  a Hungry-Goriya room.
- **Keyboard hotkeys** (while hovering): set room type / monster / floor-drop /
  door directly; arrow keys warp the cursor to adjacent cells; an "unmark-remark"
  gesture links some marks to dungeon item boxes / maybe-blockers.

Doors (`DungeonUI.fs:717-769`): left = Yes (toggles Unknown), right = No, middle =
Yellow, wheel cycles; shift reverses. **Door inference**: marking a room can
auto-set one adjacent Unknown door to Yes (option-gated).

Power tools: **drag-paint** rooms; a **GRAB** cut-&-paste of a contiguous dungeon
segment; a 10th **Summary tab** (3×3 dungeon minis).

Pickers (`DungeonPopups.fs`): modal icon grids — Room-Type (7×5), Monster (8×4),
Floor-Drop (3×3) — each with a live preview + description; transport cells disable
when the pair is full.

---

## 4. Reference layout & our adaptation

Reference is a fixed **768-px-wide** absolutely-positioned band
(`Layout.fs`, `OverworldItemGridUI.fs:33-45`):

```
x:0                              450                        768
 ┌──────────────────────────────┬──────────────────────────┐ dungeon area top
 │  DUNGEON TAB AREA             │  BLOCKERS grid (3×3, 108) │
 │  9 level tabs + Summary       ├──────────────────────────┤
 │  8×8 room grid (396 wide)     │  NOTES (multiline,        │
 │  + local item/triforce inset  │  ~318×252, lime-on-black) │
 └──────────────────────────────┴──────────────────────────┘
            ↓ (timeline below — out of scope)
```

Room cell pitch: 51px col × 39px row (39×27 body + gaps). Numeral watermark
behind each grid.

**Our adaptation (aesthetic licence, per the project's responsive-layout ADR
0003):** don't copy pixel offsets. Use SwiftUI flexible layout — a dungeon
tab-strip + room grid on the left, blockers + notes stacked on the right, all
reflowing with the window. Keep the *proportions* and the left/right split, but
size relative to the map above. This matches how the top section was already
adapted.

---

## 5. Blockers UI (model already exists)

Reference grid (`UIComponents.fs:955-997`): a **3×3** grid, cell 0,0 is the
"BLOCKERS" label; the other 8 cells are dungeons 1–8, each a row of **3 blocker
boxes** with a 1-char label (turns white when the dungeon is located).

Per box (`UIComponents.fs:804-952`, `Views.fs:417-436`):
- **Left-click** → kind picker (grid of all `DungeonBlocker` kinds; disabled kinds
  the player can't be blocked by). **Wheel** → same picker pre-scrolled.
- **Middle-click OR Shift+Left** → "Applies to…" popup: checkboxes for
  `[Map, Compass, Triforce, Item Box 1/2/3]` + All/None (box 3 only when the
  dungeon has 3 boxes).
- **Hover** → highlight the matching overworld shop (meat/key/bomb/arrow/rupee).
- Visual: 30×30 box; **border gradient** green→red = a MAYBE blocker, gray =
  NOTHING, light-gray = a definite blocker; kind icon inside; MAYBE also gets a
  background wash.

Our model already has all of this (`DungeonBlocker` 16-case enum,
`DungeonBlockersContainer` 8×3, `appliesTo[6]`, `asJsonString`) — **only the view
is missing**. The "Applies to" chips render onto the dungeon's own triforce/box
widgets in the reference (`Views.fs:129-146`), which we'll adapt.

---

## 6. Notes

One **global** multiline text box (`WPFUI.fs:1219-1229`) — lime-green on black,
below the blockers, seeded "Notes". Greenfield in our app (no model/UI). Trivial:
a `String` on the model + a `TextEditor`. (Persistence rides with the future
save/load; for now it's session state.)

---

## 7. Current app: what exists vs the gap

**Exists (model + top-section UI):** `Dungeon`, `DungeonTrackerInstance`, `Box`
(cellCurrent/playerHas/stair), HDN labelling + palette, the 9-card widget,
basement-stair glyphs, the **blockers model** (+ reminder-engine consumption), and
tests for all of it.

**Absent:** interior room grid, room types, doors, monsters, floor-drop-in-room,
navigable staircases, **blockers UI**, **notes**, the Summary tab.

---

## 8. Proposed Swift architecture

### TrackerCore (new, pure, testable)
- `DungeonRoom` (`@Observable` or value type): the 5 fields.
- `RoomType`, `MonsterDetail`, `FloorDropDetail`, `DoorState` enums with
  `displayName`, hot-key token (`asHotKeyName`/`fromHotKeyName` for the future
  save), and picker ordering. **Wiki-verify** ambiguous monster names before
  finalizing.
- `DungeonRoomMap` — an 8×8 room grid + `horizontalDoors[7][8]` +
  `verticalDoors[8][7]` + `roomIsCircled[8][8]` + `usedTransports` counter, with
  the transport-pair legality rule and door-inference helper. One per dungeon;
  owned by (or alongside) `DungeonTrackerInstance`.
- Old-man count derivation; the map/compass "located" derivation.

### ZTrackerMac (views)
- `DungeonRoomGridView` — the 8×8 grid; cell rendering (room-type/monster/
  floor-drop icons, entrance arrows, completion dimming, circle); door segments
  between cells; hover row/col highlight.
- Room-type / monster / floor-drop **pickers** (SwiftUI popovers or a grid modal,
  matching the existing overworld-picker idiom).
- `DungeonTabsView` — 9 level tabs (reuse `DungeonLabeling`) + the local item/
  triforce inset + Summary tab.
- `BlockersView` — the 3×3 grid over the existing container; kind picker + "Applies
  to" popup.
- `NotesView` — a `TextEditor`.
- Assemble into the middle band in `MainTrackerPlaceholderView`.

### Assets
The reference uses many dungeon-room / monster sprites (`Graphics.fs`
`dungeonRoomBmpPairs`, monster bmps). We need equivalents. **Open decision** —
extract/convert the reference sprites vs. redraw vs. SF-Symbol stand-ins (see §11).

---

## 9. Phased implementation plan (sliced PRs)

Each slice is its own reviewed PR; later slices depend on earlier ones.

- **D0 — Model foundation.** `RoomType`/`MonsterDetail`/`FloorDropDetail`/
  `DoorState` enums + `DungeonRoom` + `DungeonRoomMap` (grid, doors, circle,
  transport legality). No UI. Heavy unit tests. *(Unblocks everything.)*
- **D1 — Static room grid render.** Read-only 8×8 grid per dungeon tab: draw
  room-type/monster/floor-drop icons + completion dimming + entrance arrows +
  numeral watermark. Wire the tab strip. *(Needs assets — see §11.)*
- **D2 — Room editing.** Left/right/middle-click + wheel + the three pickers;
  entrance-cycle; complete toggle; circle toggle; floor-drop brightness.
- **D3 — Doors.** Door segments between cells + click/wheel cycling + door
  inference (option already exists: `doDoorInference`).
- **D4 — Blockers UI.** The 3×3 grid over the existing container; kind picker +
  "Applies to" popup; hover→shop locator. *(Model already done — smallest slice.)*
- **D5 — Notes.** Model field + `TextEditor` in the band.
- **D6 — Summary tab.** The 3×3 dungeon-mini overview.
- **D7 — Power tools (optional).** Keyboard hot-keys, drag-paint, GRAB. *(Lowest
  priority; gauge appetite after D2–D3.)*

Suggested order to deliver value fast: **D0 → D4 (blockers, cheap) → D5 (notes,
cheap) → D1 → D2 → D3 → D6 → D7.** This lights up the whole band's *frame* early
(blockers + notes + tabs) before the deep room-editing work.

---

## 10. Deliberate deviations & macOS adaptations

- **Middle-click**: many Mac trackpads/mice lack it. Every middle-click gesture
  (room circle, floor-drop brightness, door Yellow, blocker "Applies to") needs a
  **primary alternative** — shift-click or a context-menu item. Propose:
  shift+left as the universal middle-click stand-in, plus context-menu entries.
- **Layout**: flexible SwiftUI, not the fixed 768px canvas (ADR 0003).
- **Pickers**: SwiftUI popover/menu idiom (as the overworld picker already is),
  not the reference's bespoke modal grid — unless we want the icon-grid look.
- **GRAB / drag-paint**: power features; ship only if there's appetite (D7).

---

## 11. Decisions (RESOLVED 2026-07-15)

1. **Sprites/assets** — ✅ **Extract & convert the reference bitmaps** (most
   faithful). D1 needs an extraction step from `Graphics.fs`.
2. **Interaction model** — ✅ **Shift+click stand-in for middle-click + right-click
   context menus** as the discoverable fallback for everything.
3. **Power tools (D7)** — ✅ **All in scope** (drag-paint, GRAB), EXCEPT keyboard
   **hot-keys**: ship only a **basic placeholder** now (a visible "coming soon"
   stub) — the actual key-binding work is deferred to the separate app-wide
   hotkeys conversation.
4. **Summary tab (D6)** — ✅ **In scope** (build it).
5. **Delivery order** — ✅ **Frame first.** Slice order: Notes + band scaffold →
   Blockers UI → D0 room model → grid render → editing → doors → Summary → power
   tools.

---

## 12. Seven strategic lenses

- **CEO / reputational** — this is *the* parity gap; shipping it is what makes the
  app usable. Low political risk; high credibility payoff.
- **Purchasing / ROI** — large build, but it's the highest-leverage work; unblocks
  save/load and "real use". Worth it.
- **Product/PM** — buildable, but big — hence the slices. Risk = scope creep into
  power tools; mitigated by making D7 optional.
- **Middle-management / daily use** — this is the screen a runner stares at most.
  Must be fast and legible; the room grid's readability is the make-or-break.
- **Developer** — clean separation (pure model in TrackerCore, views on top) keeps
  it testable and matches the existing architecture. Asset pipeline is the main
  unknown.
- **Investor / moat** — full parity with the canonical tracker is the credibility
  bar for a native macOS alternative.
- **Marketing** — "the whole tracker, native on Mac" only becomes true with this.
- **Conflict:** Developer (asset effort) vs Product (want it faithful) — resolved
  by decision #1 (start with stand-ins if needed, upgrade art later).

---

## 13. Testing strategy & risks

- **Model (D0)**: exhaustive unit tests — enum round-trips, transport-pair
  legality, door-inference, old-man count, completion logic. This is where
  correctness lives and it's fully headless-testable.
- **Views**: on-device verification per slice (the established pattern), plus view
  tests where feasible.
- **Risks:** (a) asset pipeline unknown (decision #1); (b) the door coordinate
  transpose (`[j][i]`) is easy to get wrong — the reference's serialization agent
  flagged it; encode it once in the model and test it; (c) interaction density on
  macOS (decision #2).

---

## 14. Scoping sign-offs (single-operator review)

- [x] **Analyst** — scope bounded (room grid + blockers UI + notes); intra-room
      maps / drawing / timeline / save explicitly excluded; sliced into
      reviewable PRs.
- [x] **Architect** — pure model in TrackerCore, views on top; matches ADR 0001/
      0003. Asset pipeline is the one open architectural question (#1).
- [x] **Data** — model mirrors the reference's per-room fields + per-dungeon door/
      circle/transport structures; hot-key tokens included for the eventual save
      format; the `[j][i]` transpose is called out.
- [x] **Frontend** — components map cleanly onto SwiftUI; middle-click needs a
      documented alternative (#2).
- [x] **UX** — legibility of the room grid is the priority; middle-click
      alternatives + flexible layout are the key UX calls.
- [x] **SDET** — the model slice (D0) is heavily unit-testable; view slices use
      on-device verification.
- [x] **Backend/DevOps** — N/A (client-only).
- [ ] **Awaiting user decisions** (§11) before D0 kicks off.
