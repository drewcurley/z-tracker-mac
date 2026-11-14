/// A z1r gameplay tip/factoid shown on the startup screen (docs/domain.md § 4.1).
public struct Tip: Identifiable, Equatable, Sendable {
    public let id: String
    public let text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

/// The startup "Random tip:" pool (T-250) — the reference's full `Factoids` list
/// (`Z1R_Tracker/DungeonData.fs:3-65`). Gameplay tips are verbatim. The Z-Tracker tips are
/// reworded where this app works differently (⌘-click doors, Settings ▸ hotkeys, Notes.txt in
/// the save folder, "Highlight nearby" tint); three are left out because their feature isn't
/// here (the hover "?" explainer, the item box beside the dungeon map, overworld circles).
public enum TipProvider {
    /// `noviceTips` (`DungeonData.fs:4-17`).
    public static let noviceTips: [Tip] = [
        Tip(id: "novice-1", text: "Damage table: wood sword=1; white sword=2; magic sword=4; wand(melee or beam)=2; wood arrow=2; silver arrow=4; fire=1; bomb explosion=4; boomerang=0 (some enemies have 0 HP and can be killed by boomerang)"),
        Tip(id: "novice-2", text: "If an overworld screen has 6 monsters, and you kill 2 and leave the screen, only 4 will spawn when you next return.  Overworld monsters can fully respawn only after a screen is fully cleared, or after a save."),
        Tip(id: "novice-3", text: "If a dungeon room has 6 monsters, and you kill 2 and leave the room, only 4 will spawn when you next return.  Dungeon monsters can fully respawn only after a room is fully cleared, or after the player leaves the dungeon."),
        Tip(id: "novice-4", text: "Each seed has its own specific value for small/medium/large secrets, where the possible ranges for any seed are 1-20/25-40/50-150 rupees."),
        Tip(id: "novice-5", text: "Sometimes buying 2 blue potions is cheaper than buying a red one.  Buying a blue potion when you have a blue potion turns it into a red potion."),
        Tip(id: "novice-6", text: "For the Any Roads, from your current entrance, the 3 staircases go +1/+2/+3 steps along the 1-2-3-4-1-2-3-4-... chain."),
        Tip(id: "novice-7", text: "To stun a Dodongo with a single bomb, walk halfway between two tiles when placing the bomb; Dodongo can only eat bombs placed evenly on the tile grid.  After being stunned, Dodongo can be killed with a sword for a bomb pack drop."),
        Tip(id: "novice-8", text: "When there is a standing item drop on the floor of a dungeon room when you first walk in, there cannot be another prize drop for killing all monsters in the room."),
        Tip(id: "novice-9", text: "If a dungeon room has a pushblock, it will always be the leftmost block of the middle row."),
        Tip(id: "novice-10", text: "Overworld push-blocks (such as rocks that can be pushed with power bracelet) must be pushed up/down from directly below/above the block.  In contrast, dungeon pushblocks are pushable in all 4 directions."),
        Tip(id: "novice-11", text: "Generally/roughly, the higher the dungeon number, the larger the dungeon is likely to be, and the less likely a given wall will be bombable."),
        Tip(id: "novice-12", text: "If you UP+A out of a door repair charge room before the NPC finishes speaking and starts taking your money, you can avoid the charge."),
    ]

    /// `intermediateTips` (`DungeonData.fs:18-35`).
    public static let intermediateTips: [Tip] = [
        Tip(id: "intermediate-1", text: "A room with a gleeok cannot have a push block."),
        Tip(id: "intermediate-2", text: "While most dungeon 'old man' rooms can be shuffled in 1Q/Shapes dungeons, there is one exception: a bomb upgrade can never appear in level 9."),
        Tip(id: "intermediate-3", text: "The first two rooms of Level 9 (lobby and old man) never contain any bombable walls."),
        Tip(id: "intermediate-4", text: "If you defeat 1 of 2 Lanmolas/Moldorms, or 1 of 3 small Digdoggers, and then leave the room, the monsters will all be gone when you return a moment later."),
        Tip(id: "intermediate-5", text: "A single dodongo in a room is a boss (will not respawn if killed and room is exited).  Three dodongos in a room is an enemy group (that can respawn)."),
        Tip(id: "intermediate-6", text: "If you pirouette a dungeon entrance (walk out, walk right back in), you will unlock or bomb-hole a possible doorway on the wall opposite the entrance."),
        Tip(id: "intermediate-7", text: "If you screen transition (e.g. from East to West) on the Overworld before entering a dungeon, you may unlock a doorway or uncover a free bomb-hole on the wall you came from (e.g. East)."),
        Tip(id: "intermediate-8", text: "If a room has a shutter door, a push block cannot reveal a new staircase (just will open the shutter if pushable)."),
        Tip(id: "intermediate-9", text: "Consider the room that has the triforce in vanilla; in Shapes dungeons, when that room does not have a standing item upon entry, it will always drop the Map after killing all enemies. (Exception: in L9 adjacent to Zelda's room, there may be no drop.)"),
        Tip(id: "intermediate-10", text: "When playing 'swordless', the only way to defeat a gleeok is with a wand, and the only way to defeat wizzrobes is with explosions (from bombs or boomstick)."),
        Tip(id: "intermediate-11", text: "If a dungeon is on screen A15, recorder-ing to that dungeon will cause the whirlwind drop you at B15, as there's not space on A15 to land."),
        Tip(id: "intermediate-12", text: "If you clear a dungeon room containing traps or bubbles, it will stay clear forever until you leave the dungeon (as traps & bubbles are considered enemies)."),
        Tip(id: "intermediate-13", text: "UP+A-continue/save during a fairy fountain refill returns you to your starting screen on the overworld with full health."),
        Tip(id: "intermediate-14", text: "Bomb upgrade man never has a bombable north wall, nor do rooms containing dungeon NPCs who give hints. On the other hand, muggers and Hungry Goriya can have bombable north walls."),
        Tip(id: "intermediate-15", text: "Standing just halfway out the east door of a dungeon room makes the player immune to some attacks; this 'safety door' strategy can be effective to shoot beam swords at gleeoks or lanmola, for example."),
    ]

    /// `advancedTips` (`DungeonData.fs:36-45`).
    public static let advancedTips: [Tip] = [
        Tip(id: "advanced-1", text: "Zelda's shutter will always be the only shutter door in a room. If you see 2+ shutter doors, none of them are Zelda's. Exceptions: If Zelda is adjacent to Gannon, Gannon's room may have multiple shutter doors. If Gannon is not required, Zelda can be anywhere, including rooms without shutters."),
        Tip(id: "advanced-2", text: "If you have 0 keys, and a room has both a shutter and a locked door, and you press against the locked door the moment the shutter opens, you can go through the door without a key, unlocking it (khananakey)."),
        Tip(id: "advanced-3", text: "If using 'Level 9 Entry: Random' flag, if the old man at the door tells you some nonsense, that means you need all 8 triforces to get in. Otherwise he will say 'only those with X triforces' or 'only those with candle' etc."),
        Tip(id: "advanced-4", text: "In Shapes (1Q) dungeons, after clearing monsters, dungeon room 'five pairs' can only drop in dungeon 1, and dungeon room 'maze' can only drop in dungeon 4."),
        Tip(id: "advanced-5", text: "In 1QL5, the floor drop spawn for 'tee' room is on the island; in L4, it's bottom right of the tee room; in most other dungeons, it's top right of the tee room."),
        Tip(id: "advanced-6", text: "These dungeon room never drop in 1Q/Shapes after clearing monsters: '3 full rows', 'Zelda room', 'circle wall', 'single block', and '<spike trap angles>'."),
        Tip(id: "advanced-7", text: "If the 'Add 2nd Quest Doors' randomizer flag is used, walk-through-walls will never appear in levels 1, 3, or 7, but walk-through-walls may appear in any other dungeon."),
        Tip(id: "advanced-8", text: "In 1Q/Shapes dungeons, a room with a standing-drop or kill-prize-drop or shutter-door never has a push-block-that-reveals-a-new-stair. Exception: if 'Remove Most Open Stairs' flag is used, then a non-shutter room with a standing item can have a push-block-revealed-stair."),
    ]

    /// `zTrackerTips` (`DungeonData.fs:46-59`), adapted to this app.
    public static let zTrackerTips: [Tip] = [
        Tip(id: "ztracker-shop-items", text: "In Z-Tracker, each overworld shop can be marked with more than one item for sale.  Left-click a shop tile to change it or add another item."),
        Tip(id: "ztracker-found-dungeons", text: "In Z-Tracker, when you locate a dungeon entrance on the overworld map, its triforce numeral lights up on the top of the tracker, so that it is easy to see which dungeons you have/haven't yet found."),
        Tip(id: "ztracker-doors", text: "In Z-Tracker, left-clicking a dungeon door makes it a green door (can go), right-clicking makes it a red wall (can't go), ⌘-clicking (or middle-clicking) makes it a yellow door (other, perhaps a locked door), and scrolling cycles the door's color; on an unmarked door, scroll up for purple (perhaps a shutter) or down for gold."),
        Tip(id: "ztracker-rooms", text: "In Z-Tracker, left-clicking a dungeon's entrance room cycles the entrance arrow (SWNE), and left-clicking most other rooms toggles them completed (darker) or uncompleted (brighter)."),
        Tip(id: "ztracker-blockers", text: "In Z-Tracker, if you leave a dungeon because you are blocked (e.g. needing a Ladder or a Key), you can add a mark in the BLOCKERS section for that dungeon number, to remind you why you left."),
        Tip(id: "ztracker-timeline", text: "In Z-Tracker, the Timeline at the bottom of the app is automatically tracking 'splits' of when you got each triforce piece (as well as every other key item)."),
        Tip(id: "ztracker-hotkeys-notes", text: "In Z-Tracker, Settings ▸ Edit hotkeys… sets up keyboard shortcuts (and can import a Windows HotKeys.txt).  Put a Notes.txt in ~/Documents/ztracker to pre-populate the Notes text in the app, as well."),
        Tip(id: "ztracker-highlight-nearby", text: "In Z-Tracker, with \"Highlight nearby\" on, hovering the overworld map tints tiles green if you can uncover a location there, yellow if the screen may or may not yield a location and you can uncover it, or red if you don't have the item to uncover a location there."),
        Tip(id: "ztracker-credit", text: "Dr. Brian Lorgon111 made Z-Tracker for Windows, which this Mac app is ported from.  Send him some love on twitch (lorgon) or on YouTube (lorgon111)."),
    ]

    /// Beyond the reference — sourced from https://z1r.fandom.com/wiki/Boomstick (2026-07-02).
    public static let extraTips: [Tip] = [
        Tip(id: "boomstick", text: "In a \"Boomstick\" seed, once you get the Book your Wand shoots "
            + "explosions instead of fire — usable like Bombs, but they won't kill (only stun) a Dodongo."),
    ]

    public static let allTips: [Tip] = noviceTips + intermediateTips + advancedTips + zTrackerTips + extraTips

    /// One random tip per launch, as the reference's startup screen (`Program.fs:885-894`).
    public static func random() -> Tip {
        allTips.randomElement() ?? allTips[0]
    }
}
