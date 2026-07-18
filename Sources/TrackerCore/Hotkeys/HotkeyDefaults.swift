import Foundation

/// The built-in default binding scheme (T-135), designed for the **right half of a
/// split keyboard** (the half that starts F7 / 7 / Y / H / N) and using only the
/// no-modifier → Shift → Option tiers (never Command — OS-reserved — nor Control —
/// absent from the right side of a Mac board).
///
/// The design that makes ~200 selectors fit without collisions:
///  • **Region** contexts (items / overworld / blockers / dungeon rooms / hint zones)
///    draw from the right-half **typing block** (25 keys). Because each region is its
///    own conflict scope, the *same* key means different things in different regions
///    — so all five share one 25-key palette, tiered none → Shift → Option.
///  • **Global** keys live on the **nav cluster + F-keys + arrows/space**, which no
///    region uses — so a Global can never clash with a region mark.
///
/// Sub-group tiers follow the user's rule: dungeon **room types** on plain keys,
/// **monsters** on Shift, **floor drops** on Option. The 8 door-nudge selectors are
/// left unbound by default (niche; doors are usually dragged) — everything else binds.
public enum HotkeyDefaults {
    /// The 25-key right-half typing block, in reading order. Letters/digits store the
    /// character; punctuation stores its raw Mac key code (`\nnn`) — matching how a
    /// live key-down is captured, so defaults dispatch identically.
    static let palette: [String] = [
        "7", "8", "9", "0", "\\27", "\\24",          // 7 8 9 0 - =
        "y", "u", "i", "o", "p", "\\33", "\\30", "\\42", // Y U I O P [ ] \
        "h", "j", "k", "l", "\\41", "\\39",          // H J K L ; '
        "n", "m", "\\43", "\\47", "\\44",            // N M , . /
    ]

    private static func chord(_ token: String, _ mod: HotkeyChord.Modifier = .none) -> HotkeyChord {
        HotkeyChord(modifier: mod, key: token)
    }

    /// Assign a context's selectors (in catalog order) to `palette`, filling the
    /// none tier, then Shift, then Option.
    private static func tier(_ ids: [String], into out: inout [String: HotkeyChord]) {
        let tiers: [HotkeyChord.Modifier] = [.none, .shift, .option]
        for (i, id) in ids.enumerated() {
            let t = i / palette.count
            guard t < tiers.count else { break }   // ran out of key space; leave unbound
            out[id] = chord(palette[i % palette.count], tiers[t])
        }
    }

    /// The full default binding set.
    public static func bindings() -> [String: HotkeyChord] {
        var out: [String: HotkeyChord] = [:]

        // ── Region contexts: shared 25-key palette, tiered none → Shift → Option ──
        tier(HotkeyCatalog.selectors(in: .items).map(\.id), into: &out)
        tier(HotkeyCatalog.selectors(in: .overworld).map(\.id), into: &out)
        tier(HotkeyCatalog.selectors(in: .hintZones).map(\.id), into: &out)
        tier(HotkeyCatalog.selectors(in: .contextual).map(\.id), into: &out)

        // Blockers: the 8 primaries on plain keys; each "Maybe_" on Shift+its primary
        // (so Ladder=K, Maybe-ladder=⇧K); Nothing on the next plain key.
        let blockers = HotkeyCatalog.selectors(in: .blockers).map(\.id)
        let primaries = blockers.filter { !$0.contains("Maybe") && !$0.hasSuffix("Nothing") }
        for (i, id) in primaries.enumerated() { out[id] = chord(palette[i]) }
        for id in blockers where id.contains("Maybe") {
            let base = id.replacingOccurrences(of: "Blocker_Maybe_", with: "Blocker_")
            if let i = primaries.firstIndex(of: base) { out[id] = chord(palette[i], .shift) }
        }
        out["Blocker_Nothing"] = chord(palette[primaries.count])

        // Dungeon rooms: room types → plain, monsters → Shift, floor drops → Option.
        // (One continuous tiered run over room types + monsters + floor drops packs
        // them into none/Shift/Option in exactly that priority order.)
        let dr = HotkeyCatalog.selectors(in: .dungeonRoom).map(\.id)
        let roomTypes = dr.filter { $0.contains("_RoomType_") }
        let monsters = dr.filter { $0.contains("_MonsterDetail_") }
        let floorDrops = dr.filter { $0.contains("_FloorDropDetail_") }
        tier(roomTypes + monsters + floorDrops, into: &out)   // doors intentionally unbound

        // ── Globals: nav cluster + F-keys + arrows/space (regions never use these) ──
        // Cursor movement — arrows.
        out["Global_MoveCursorLeft"]  = chord("\\123")
        out["Global_MoveCursorRight"] = chord("\\124")
        out["Global_MoveCursorUp"]    = chord("\\126")
        out["Global_MoveCursorDown"]  = chord("\\125")
        // Region cycle — PgDn forward, ⇧PgDn back (user's mapping).
        out["Global_CycleRegionForward"]  = chord("\\121")
        out["Global_CycleRegionBackward"] = chord("\\121", .shift)
        // Timer — Space start, ⇧Space groundhog reset.
        out["Global_StartTimer"]     = chord("\\49")
        out["Global_GroundhogReset"] = chord("\\49", .shift)
        // Whistle destination — Home ◀ / End ▶.
        out["Global_RecorderDestPrev"] = chord("\\115")
        out["Global_RecorderDestNext"] = chord("\\119")
        // Mouse at cursor — Enter=left, FwdDel=right, PgUp=middle, ⌥↑/⌥↓=scroll.
        out["Global_LeftClick"]   = chord("\\36")
        out["Global_RightClick"]  = chord("\\117")
        out["Global_MiddleClick"] = chord("\\116")
        out["Global_ScrollUp"]    = chord("\\126", .option)
        out["Global_ScrollDown"]  = chord("\\125", .option)
        // Dungeon tabs — plain F7–F10 = 1–4, ⇧F7–⇧F12 = 5–9,Summary.
        // (Deliberately avoids *plain* F11/F12: macOS reserves them for Show Desktop
        // / Dashboard and the WindowServer eats them before any app monitor — a
        // Shift/Option modifier dodges that. See T-135.)
        let fkeys = ["\\98", "\\100", "\\101", "\\109", "\\103", "\\111"]   // F7…F12
        for (i, id) in ["Global_DungeonTab1","Global_DungeonTab2",
                        "Global_DungeonTab3","Global_DungeonTab4"].enumerated() {
            out[id] = chord(fkeys[i])                                        // F7–F10
        }
        for (i, id) in ["Global_DungeonTab5","Global_DungeonTab6","Global_DungeonTab7",
                        "Global_DungeonTab8","Global_DungeonTab9","Global_DungeonTabS"].enumerated() {
            out[id] = chord(fkeys[i], .shift)                                // ⇧F7–⇧F12
        }
        // Item toggles — ⌥F7…F12 (6) + ⌥Home, ⌥End, ⌥PgUp (3). All safe: only
        // *plain* F11/F12 are OS-reserved, and these nav keys are free with ⌥.
        let toggles = ["Global_ToggleMagicalSword","Global_ToggleWoodSword","Global_ToggleBoomBook",
                       "Global_ToggleBlueCandle","Global_ToggleWoodArrow","Global_ToggleBlueRing",
                       "Global_ToggleBombs","Global_ToggleGannon","Global_ToggleZelda"]
        let toggleChords: [HotkeyChord] = [
            chord("\\98", .option), chord("\\100", .option), chord("\\101", .option),
            chord("\\109", .option), chord("\\103", .option), chord("\\111", .option),
            chord("\\115", .option), chord("\\119", .option), chord("\\116", .option),
        ]
        for (i, id) in toggles.enumerated() { out[id] = toggleChords[i] }

        return out
    }
}
