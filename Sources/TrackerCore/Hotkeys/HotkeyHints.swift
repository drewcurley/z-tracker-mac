/// In-menu hotkey hints (T-197, coverage §1 #3b) — the reference shows a choice's bound
/// key inline in its menu/label (`AppendHotKeyToDescription`, `OverworldItemGridUI.fs:139`).
/// This maps a menu choice (an overworld mark or a hint zone) to its `HotKeys.txt` selector,
/// then formats the bound chord as a short inline suffix like `" (B)"` — empty when unbound.
///
/// The mark→selector and zone→selector maps are derived by iterating the catalog and reusing
/// the existing `fromHotkeySuffix` / `fromHotKeyName` parsers, so there's no second mapping to
/// keep in sync.
public enum HotkeyHints {
    private static let overworldPrefix = "Overworld_"
    private static let hintZonePrefix = "HintZone_"

    /// mark → `Overworld_*` selector id.
    private static let overworldSelectorByMark: [OverworldTileMark: String] = {
        var out: [OverworldTileMark: String] = [:]
        for sel in HotkeyCatalog.selectors(in: .overworld) {
            let suffix = String(sel.id.dropFirst(overworldPrefix.count))
            if let mark = OverworldTileMark.fromHotkeySuffix(suffix) { out[mark] = sel.id }
        }
        return out
    }()

    /// hint zone → `HintZone_*` selector id.
    private static let hintZoneSelectorByZone: [HintZone: String] = {
        var out: [HintZone: String] = [:]
        for sel in HotkeyCatalog.selectors(in: .hintZones) {
            let suffix = String(sel.id.dropFirst(hintZonePrefix.count))
            if let zone = HintZone.fromHotKeyName(suffix) { out[zone] = sel.id }
        }
        return out
    }()

    public static func selectorID(for mark: OverworldTileMark) -> String? { overworldSelectorByMark[mark] }
    public static func selectorID(for zone: HintZone) -> String? { hintZoneSelectorByZone[zone] }

    /// A short inline suffix for a selector's bound chord, e.g. `" (B)"` / `" (⇧4)"`, or `""`
    /// when the selector is unknown or unbound. Leading space so it appends cleanly to a label.
    public static func suffix(forSelectorID id: String?, config: HotkeyConfig) -> String {
        guard let id, let chord = config.chord(for: id) else { return "" }
        return " (\(chord.displayName))"
    }

    /// Convenience: the inline suffix for an overworld mark / a hint zone.
    public static func suffix(for mark: OverworldTileMark, config: HotkeyConfig) -> String {
        suffix(forSelectorID: selectorID(for: mark), config: config)
    }
    public static func suffix(for zone: HintZone, config: HotkeyConfig) -> String {
        suffix(forSelectorID: selectorID(for: zone), config: config)
    }

    /// The bare key label for a bound chord (e.g. `"B"`, `"⇧4"`), or `""` when unbound —
    /// for a compact in-cell badge rather than the parenthesized inline `suffix`.
    public static func keyLabel(forSelectorID id: String?, config: HotkeyConfig) -> String {
        guard let id, let chord = config.chord(for: id) else { return "" }
        return chord.displayName
    }
    public static func keyLabel(for mark: OverworldTileMark, config: HotkeyConfig) -> String {
        keyLabel(forSelectorID: selectorID(for: mark), config: config)
    }
    public static func keyLabel(for zone: HintZone, config: HotkeyConfig) -> String {
        keyLabel(forSelectorID: selectorID(for: zone), config: config)
    }
}
