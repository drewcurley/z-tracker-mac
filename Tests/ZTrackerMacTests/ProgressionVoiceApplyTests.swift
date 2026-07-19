import Testing
import TrackerCore
@testable import ZTrackerMac

/// Voice progression toggles (T-142) — the item-grid "acquired" boxes, with the
/// user's overworld/global scoping.
@MainActor
struct ProgressionVoiceApplyTests {
    @Test func overworldItemAppliesOnlyInOverworldRegion() {
        let progress = PlayerProgressAndTakeAnyHearts()
        // Wrong region → not applied.
        #expect(ProgressionVoiceApply.apply(id: "Prog_WoodSword", region: .dungeonMap, progress: progress) == false)
        #expect(progress.hasWoodSword == false)
        // Overworld region → applied.
        #expect(ProgressionVoiceApply.apply(id: "Prog_WoodSword", region: .overworld, progress: progress))
        #expect(progress.hasWoodSword)
    }

    @Test func bombsAndEndStatesAreGlobal() {
        let progress = PlayerProgressAndTakeAnyHearts()
        #expect(ProgressionVoiceApply.apply(id: "Prog_Bomb", region: .dungeonMap, progress: progress))
        #expect(progress.hasBombs)
        #expect(ProgressionVoiceApply.apply(id: "Prog_Ganon", region: .blockers, progress: progress))
        #expect(progress.hasDefeatedGanon)
        #expect(ProgressionVoiceApply.apply(id: "Prog_Zelda", region: .items, progress: progress))
        #expect(progress.hasRescuedZelda)
    }

    @Test func acquisitionIsDirectionalNotToggling() {
        let progress = PlayerProgressAndTakeAnyHearts()
        progress.hasMeat = true
        // Saying it again keeps it on (set-true, not flip), so a double-recognition
        // can't un-mark it.
        #expect(ProgressionVoiceApply.apply(id: "Prog_Meat", region: .overworld, progress: progress))
        #expect(progress.hasMeat)
    }

    @Test func clearSetsFlagFalseFromAnyRegion() {
        // Un-mark (T-149): value:false clears, and isn't region-gated (undo from anywhere).
        let progress = PlayerProgressAndTakeAnyHearts()
        progress.hasWoodSword = true
        #expect(ProgressionVoiceApply.apply(id: "Prog_WoodSword", region: .dungeonMap,
                                            progress: progress, value: false))
        #expect(progress.hasWoodSword == false)
    }

    @Test func unknownIdIsNotApplied() {
        let progress = PlayerProgressAndTakeAnyHearts()
        #expect(ProgressionVoiceApply.apply(id: "Prog_Nope", region: .overworld, progress: progress) == false)
    }

    @Test func everyProgressionCatalogIdMaps() {
        // Every Prog_* catalog action must have a toggle mapping, or a voice phrase
        // would silently no-op.
        for action in VoiceCatalog.all where action.category == .progression {
            #expect(ProgressionVoiceApply.toggle(forID: action.id) != nil, "no toggle for \(action.id)")
        }
    }
}
