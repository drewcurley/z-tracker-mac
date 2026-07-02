# Data Model — z-tracker-mac

**Status:** forward-looking / PLANNED. No code exists yet. The schema below is
transcribed from the reference app's proven save format (`Zelda1RandoTools`,
`SaveAndLoad.fs`) as the starting design, not as something already implemented
here. See `contracts.md` § 1 for the file-level contract list this schema
backs.

**Verification:** field list grounded by reading `SaveAndLoad.fs:300-389` in
`Zelda1RandoTools` during the 2026-07-02 inventory pass (see `domain.md`).
Some nested sub-schemas were not fully transcribed — marked UNKNOWN below,
not guessed.

## 1. Storage

No database. Three flavors of a single JSON document shape, written as plain
files:

| File | Trigger | Filename pattern (reference app) |
|---|---|---|
| Autosave | Periodic timer (~1 min) | `zt-save-zz-autosave.json` (single file, overwritten) |
| Manual save | User clicks "Save" | `zt-save-manual-YYYY-MM-DD-HH-mm-ss.json` |
| Finished save | Optional, on Ganon+Zelda completion | `zt-save-completed-YYYY-MM-DD-HH-mm-ss.json` |

**Location — resolved (ADR 0002):** `~/Library/Application Support/com.drewcurley.ztrackermac/`,
implemented as `TrackerCore.SaveDirectoryLocator.appSupportDirectory()`
(`Sources/TrackerCore/SaveDirectoryLocator.swift`), covered by
`Tests/TrackerCoreTests/SaveDirectoryLocatorTests.swift`. The reference app's
"next to the executable" approach is not viable for a signed/notarized macOS
app bundle; this is the standard macOS location for app-owned data instead.

A **separate** file holds options/settings (independent lifecycle from saves;
exact reference-app filename not transcribed — see `domain.md` § 6).

## 2. Save-document schema (top-level shape, ported from the reference app)

```
SaveDocument
├── Version: Int
├── TimeInSeconds: Int
├── Overworld
│   ├── Quest: enum (First | Second | MixedFirst | MixedSecond)
│   ├── MirrorOverworld: Bool
│   ├── StartIcon: { X: Int, Y: Int }
│   ├── CustomWaypoint: { X: Int, Y: Int }
│   └── Map: [Int]                          # 38 tile-mark types, see domain.md § 4.5
├── Items
│   ├── HiddenDungeonNumbers: Bool
│   ├── SecondQuestDungeons: Bool
│   ├── WhiteSwordBox / LadderBox / ArmosBox: <item-box state>
│   └── Dungeons: [                          # 9 entries
│         { Triforce: Bool, Color: <enum>, LabelChar: Char,
│           PlayerHasMap: Bool,
│           Boxes: [ { CellCurrent: <enum 15 items>, PlayerHas: <tri-state> } ] }
│       ]
├── PlayerProgressAndTakeAnyHearts
│   ├── TakeAnyHearts: [Bool] (4)
│   └── HaveFlags: [Bool] (9)
├── StartingItemsAndExtras                   # 16 fields incl. HDN starting
│   └── ...                                  # triforce pieces, MaxHeartsDifferential — UNKNOWN, full field list
├── Blockers: [ { Kind: <enum, 8 values>, AppliesTo: [Bool] (6) } ]
├── Hints
│   ├── LocationHints: [Int] (11)
│   ├── NoFeatOfStrengthHint: Bool
│   └── SailNotHint: Bool
├── Notes: String
├── CurrentRecorderDestinationIndex: Int
├── RecorderToNew / RecorderToUnbeatenDungeons: Bool
├── IsBoomstickSeed / IsAtlasSeed / IsWSMSReplacedByBUSeed: Bool
├── DungeonTabSelected: Int
├── DungeonMaps: [ <per-dungeon room/door/circle grid> ]   # UNKNOWN — see § 4
├── UserCustomChecklist: <object>            # see contracts.md § 1 entry 7
├── DrawingLayerIcons: [<object>]
├── AlternativeOverworldMapFilename: String?
├── ShouldInitiallyHideOverworldMap: Bool
├── Seed: String
├── Flags: String
├── OverworldSpotsRemainingOverTime: [Int]   # for the timeline trend graph
└── Timeline: [ { Ident: String, Seconds: Int, Has: Bool } ]
```

**Backward compatibility (reference app):** the loader reads "one version
back" — i.e., tolerates the immediately-prior schema version, not arbitrary
history. Whatever version scheme this project adopts must decide its own
tolerance window explicitly (see § 4 open questions), not assume the same rule.

## 3. Options/settings document

Separate JSON file. Confirmed fields (non-exhaustive — see `domain.md` § 4.9
for the categorized feature list; the exact JSON key names were not
transcribed field-by-field during the inventory pass): dozens of boolean
toggles (routing/highlighting, window/broadcast, workflow, speech), per-category
reminder toggles (7 categories), 14 `HideOverworldTile_*` toggles, window
positions for broadcast/pop-out/magnifier windows (stored as strings), and a
`PreferredVoice` string.

## 4. Open questions — must resolve before implementing this schema

- **Compatibility decision (the big one, see `domain.md` § 6):** does
  `z-tracker-mac` read the reference app's exact JSON schema (enables
  importing existing `.json` saves from `Zelda1RandoTools`) or define its own?
  This doc assumes nothing here — pick one and record it as an ADR before
  writing the `Codable` types.
- **Exact per-dungeon `DungeonMaps` sub-schema** — the container is confirmed;
  each room's field layout lives in the reference app's `DungeonSaveAndLoad.fs`
  and was not transcribed. Needed before dungeon-tab persistence can be built.
- **`StartingItemsAndExtras`'s full 16-field list** — only partially
  enumerated during the inventory pass. Read the reference source directly
  before implementing this section rather than guessing the remaining fields.
- **Options file's exact filename and full field-by-field key list** — not
  transcribed; read `TrackerModelOptions.fs` (`readSettings`/`writeSettings`)
  directly when implementing.

## Update-this-doc-when

Update this file the moment the save/options `Codable` types are actually
implemented — replace every UNKNOWN and "ported from reference" note with the
real, current schema and its Swift type names, and record the schema-version
policy this project actually adopted.
