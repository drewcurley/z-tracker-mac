import Foundation
import Observation

/// The user's hotkey bindings (docs/domain.md § 4.11) — selector id → chord. Editable
/// in the in-app editor and importable/exportable in the Windows `HotKeys.txt` format.
/// This is the **config** only (Part A); actually firing the keys is a later phase.
@Observable
public final class HotkeyConfig {
    /// selector id (e.g. `Overworld_Level1`) → its bound chord. Absent = unbound.
    public private(set) var bindings: [String: HotkeyChord]

    @ObservationIgnored private var store: UserDefaults?
    private static let storeKey = "hotkeyBindingsText"

    public init(bindings: [String: HotkeyChord] = [:]) {
        self.bindings = bindings
    }

    /// The app entry point: bindings restored from (and saved back to) `store`.
    public static func withPersistence(store: UserDefaults = .standard) -> HotkeyConfig {
        let config = HotkeyConfig()
        if let text = store.string(forKey: storeKey) {
            config.bindings = parse(text).bindings
        }
        config.store = store
        return config
    }

    private func persist() { store?.set(exportText(), forKey: Self.storeKey) }

    public func chord(for selectorID: String) -> HotkeyChord? { bindings[selectorID] }

    /// Bind (or, with `nil`, clear) a selector. Does **not** check conflicts — the
    /// caller decides whether to proceed after `conflicts(for:chord:)`.
    public func setChord(_ chord: HotkeyChord?, for selectorID: String) {
        if let chord { bindings[selectorID] = chord } else { bindings.removeValue(forKey: selectorID) }
        persist()
    }

    /// Bind `chord` to `selectorID`, **removing it from any selectors it conflicts
    /// with** — a key is exclusive within its conflict scope, so reassigning it moves
    /// it rather than duplicating. Returns the selectors it was taken from.
    @discardableResult
    public func reassign(_ chord: HotkeyChord, to selectorID: String) -> [HotkeySelector] {
        let displaced = conflicts(for: selectorID, chord: chord)
        for selector in displaced { bindings.removeValue(forKey: selector.id) }
        bindings[selectorID] = chord
        persist()
        return displaced
    }

    /// Clear every binding.
    public func clearAll() { bindings.removeAll(); persist() }

    // MARK: Conflicts ---------------------------------------------------------------

    /// The conflict "scopes" a selector's key occupies. Two selectors clash on the
    /// same chord iff their scope sets intersect. Encodes the reference rules: keys
    /// are unique within a context; **Global** keys are unique across every
    /// non-contextual context; contextual keys are per-menu (Take-Any vs Take-This)
    /// and never clash with the rest.
    static func scopes(_ selector: HotkeySelector) -> Set<String> {
        switch selector.context {
        case .global:
            return ["items", "overworld", "blockers", "dungeonRoom", "hintZones", "global"]
        case .contextual:
            return ["contextual." + (selector.id.contains("TakeThis") ? "takeThis" : "takeAny")]
        default:
            return [selector.context.rawValue]
        }
    }

    /// The already-bound selectors (other than `selectorID`) that binding `chord`
    /// would clash with. Empty means no conflict.
    public func conflicts(for selectorID: String, chord: HotkeyChord) -> [HotkeySelector] {
        guard let target = HotkeyCatalog.selector(id: selectorID) else { return [] }
        let targetScopes = Self.scopes(target)
        return bindings.compactMap { (otherID, otherChord) -> HotkeySelector? in
            guard otherID != selectorID, otherChord == chord,
                  let other = HotkeyCatalog.selector(id: otherID),
                  !Self.scopes(other).isDisjoint(with: targetScopes) else { return nil }
            return other
        }
        .sorted { $0.id < $1.id }
    }

    // MARK: Import (HotKeys.txt → bindings) -----------------------------------------

    public struct ImportResult: Equatable, Sendable {
        public var bindings: [String: HotkeyChord]
        /// Human-readable problems (unknown selector names, unparseable values); the
        /// import still applies everything it *could* parse.
        public var warnings: [String]
    }

    /// Parse the reference `HotKeys.txt` grammar: `SelectorName = [SHIFT|CTRL|ALT ]key`,
    /// where `key` is a single printable char or `\nnn`; `#`/blank lines are comments.
    /// Lenient: unknown names / bad values are collected as warnings, not fatal.
    public static func parse(_ text: String) -> ImportResult {
        var out: [String: HotkeyChord] = [:]
        var warnings: [String] = []
        for (i, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            guard let eq = line.firstIndex(of: "=") else {
                warnings.append("Line \(i + 1): expected 'Name = key'")
                continue
            }
            let name = String(line[line.startIndex..<eq]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
            guard HotkeyCatalog.selector(id: name) != nil else {
                warnings.append("Line \(i + 1): unknown selector '\(name)'")
                continue
            }
            if value.isEmpty { continue }   // explicitly unbound
            switch parseChord(value) {
            case .some(let chord): out[name] = chord
            case .none: warnings.append("Line \(i + 1): can't parse key '\(value)' for \(name)")
            }
        }
        return ImportResult(bindings: out, warnings: warnings)
    }

    /// Parse one value token (`"SHIFT 4"`, `"a"`, `"\75"`).
    static func parseChord(_ value: String) -> HotkeyChord? {
        var modifier = HotkeyChord.Modifier.none
        var rest = value
        for mod in [HotkeyChord.Modifier.shift, .control, .option] {
            if rest.uppercased().hasPrefix(mod.rawValue + " ") {
                modifier = mod
                rest = String(rest.dropFirst(mod.rawValue.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        guard !rest.isEmpty else { return nil }
        if rest.hasPrefix("\\") {
            // Raw key code \nnn — keep verbatim (dispatch mapping is a later phase).
            guard rest.dropFirst().allSatisfy(\.isNumber), rest.count > 1 else { return nil }
            return HotkeyChord(modifier: modifier, key: rest)
        }
        guard rest.count == 1, let ch = rest.first, ch.isLetter || ch.isNumber else { return nil }
        return HotkeyChord(modifier: modifier, key: String(ch).lowercased())
    }

    /// Apply an imported set, replacing all current bindings.
    public func apply(_ result: ImportResult) { bindings = result.bindings; persist() }

    // MARK: Export (bindings → HotKeys.txt) -----------------------------------------

    /// Serialize to the reference `HotKeys.txt` format, grouped by context with the
    /// same section headers, so it round-trips into the Windows tracker.
    public func exportText() -> String {
        var lines: [String] = [
            "# Z-Tracker HotKeys",
            "#", "# General form is 'SelectorName = key'",
            "# key can be 0-9 or a-z, optionally preceded by SHIFT / CTRL / ALT,",
            "# or \\nnn for a raw key code. Blank = unbound.", "",
        ]
        for context in HotkeyContext.allCases {
            lines.append("# " + context.displayName.uppercased())
            let sels = HotkeyCatalog.selectors(in: context)
            let width = sels.map(\.id.count).max() ?? 0
            for sel in sels {
                let pad = String(repeating: " ", count: width - sel.id.count)
                lines.append("\(sel.id)\(pad) = \(bindings[sel.id]?.fileToken ?? "")")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}
