import Foundation
import Observation

/// The user's voice phrases (T-139) — action id → the phrases that trigger it. Seeded
/// from `VoiceCatalog` defaults; editable in the voice-command editor; persisted. The
/// voice analogue of `HotkeyConfig`.
@Observable
public final class VoiceConfig {
    /// action id → trigger phrases (lowercased).
    public private(set) var phrases: [String: [String]]

    @ObservationIgnored private var store: UserDefaults?
    private static let storeKey = "voicePhrasesJSON"

    public init() {
        var seeded: [String: [String]] = [:]
        for action in VoiceCatalog.all { seeded[action.id] = action.defaultPhrases }
        phrases = seeded
    }

    /// App entry point: defaults, then overlay any saved per-action phrase lists.
    public static func withPersistence(store: UserDefaults = .standard) -> VoiceConfig {
        let config = VoiceConfig()
        if let data = store.data(forKey: storeKey),
           let saved = try? JSONDecoder().decode([String: [String]].self, from: data) {
            for (id, list) in saved where VoiceCatalog.action(id: id) != nil {
                config.phrases[id] = list
            }
        }
        config.store = store
        return config
    }

    private func persist() {
        guard let store, let data = try? JSONEncoder().encode(phrases) else { return }
        store.set(data, forKey: Self.storeKey)
    }

    // MARK: Editing

    public func phrases(for id: String) -> [String] { phrases[id] ?? [] }

    public func setPhrases(_ list: [String], for id: String) {
        phrases[id] = normalize(list); persist()
    }

    public func addPhrase(_ phrase: String, to id: String) {
        let p = phrase.lowercased().trimmingCharacters(in: .whitespaces)
        guard !p.isEmpty, !(phrases[id] ?? []).contains(p) else { return }
        phrases[id, default: []].append(p); persist()
    }

    public func removePhrase(_ phrase: String, from id: String) {
        phrases[id]?.removeAll { $0 == phrase }; persist()
    }

    public func resetToDefaults() {
        for action in VoiceCatalog.all { phrases[action.id] = action.defaultPhrases }
        persist()
    }

    public func resetToDefault(id: String) {
        if let a = VoiceCatalog.action(id: id) { phrases[id] = a.defaultPhrases; persist() }
    }

    private func normalize(_ list: [String]) -> [String] {
        var seen = Set<String>(); var out: [String] = []
        for raw in list {
            let p = raw.lowercased().trimmingCharacters(in: .whitespaces)
            if !p.isEmpty, seen.insert(p).inserted { out.append(p) }
        }
        return out
    }

    // MARK: Matching

    /// An action's scope: `structural` determines the command *shape* (cursor /
    /// navigation / dungeon tab), matched at parse time; `overworld` / `dungeon` are
    /// **region actions** applied at the cursor and resolved per-region at execution.
    /// `region` (a query value) matches either overworld or dungeon.
    public enum Scope: Sendable { case structural, overworld, dungeon, region, any }

    public static func scope(of action: VoiceAction) -> Scope {
        switch action.category {
        case .cursor, .navigation, .dungeon: .structural
        case .overworldShops, .overworldMarks, .takeAny: .overworld
        case .dungeonRooms, .monsters, .floorDrops, .doors, .entrances: .dungeon
        }
    }

    private static func inScope(_ query: Scope, _ actual: Scope) -> Bool {
        switch query {
        case .any: true
        case .region: actual == .overworld || actual == .dungeon
        default: query == actual
        }
    }

    /// The best action for a set of spoken words (after any coordinate is stripped):
    /// the action with the **longest matching phrase** wins, so specific phrases
    /// ("take any potion") beat general ones ("take any"). Returns the action id and,
    /// for parametric actions, the spoken number.
    public func match(_ words: [String], scope: Scope = .any) -> (actionID: String, number: Int?)? {
        let joined = words.joined(separator: " ")
        var best: (id: String, length: Int)?
        for action in VoiceCatalog.all where Self.inScope(scope, Self.scope(of: action)) {
            for phrase in phrases(for: action.id) where joined.contains(phrase) {
                if phrase.count > (best?.length ?? -1) { best = (action.id, phrase.count) }
            }
        }
        guard let best, let action = VoiceCatalog.action(id: best.id) else { return nil }
        let number = action.takesNumber ? words.compactMap(VoiceGrammar.asInt).first : nil
        return (best.id, number)
    }

    /// All phrases across all actions — for the recognizer's `contextualStrings` bias.
    public var allPhrases: [String] { phrases.values.flatMap { $0 } }
}
