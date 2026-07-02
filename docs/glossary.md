# Glossary — z-tracker-mac

Terms used across this project's docs and (eventually) code. Sourced from the
reference app's own terminology (`Zelda1RandoTools`) so that porting
discussions stay unambiguous — see `domain.md` for the full feature context
behind each term.

**For what a randomizer flag/mechanic actually *does*** (as opposed to what
the tracker UI calls it), the authoritative source is the community wiki,
[z1r.fandom.com/wiki](https://z1r.fandom.com/wiki/) — the base game being
randomized is the original NES *The Legend of Zelda* (1986). The tracker
app's source only encodes tracking state, not game rules; an earlier draft of
this file learned that the hard way (see the "Boomstick" entry below).

| Term | Meaning |
|---|---|
| **z1r** | fcoughlin's Zelda 1 Randomizer — the game mod this app tracks progress for. Not part of this codebase. |
| **Seed** | A specific randomized z1r run, identified by a seed string + flags string. |
| **Tracker** | This app itself — a manual progress-tracking companion, not a game. |
| **GYR** | Green/Yellow/Red — the reachability convention used throughout the overworld/routing UI: green = reachable now, yellow = reachable but may not exist (mixed-quest ambiguity), red = not reachable. |
| **Quest** | Which of the four overworld layouts a seed uses: First, Second, Mixed-First, Mixed-Second. |
| **HDN** | Hidden Dungeon Numbers — a seed option that hides which numbered dungeon is which, changing several UI behaviors (see `domain.md` § 4.1–4.2). |
| **Blocker** | An item/condition marked as required to progress past a specific point in a dungeon (8 kinds — see `domain.md` § 4.7). |
| **Take-Any** | A cave type where the player picks one of several items — has a dedicated pie-menu gesture accelerator. |
| **Recorder** | An in-game item (the flute) with warp-destination mechanics the tracker helps route. |
| **Boomstick** | The result of the z1r randomizer flag "Replace Book Fire with Explosion" ([z1r wiki](https://z1r.fandom.com/wiki/Boomstick)). The Wand works normally (2 HP damage on contact/beam) until the Book is acquired; the Book becomes purchasable from a shop (swapped in at whichever shop has the highest Shield price); once acquired, the Wand shoots explosions usable like Bombs instead of fire. Explosions don't damage Link; they can stun (not kill) Dodongos. Matches the tracker's own `TrackerModel.fs` behavior (`IsCurrentlyBook`/"Boomstick Book" replacing the Book/Shield slot) and `DungeonData.fs:29`'s note that Wizzrobes/Gleeok require "explosions (from bombs or boomstick)" when swordless. *(A prior draft of this entry guessed "Bow + Boomerang merged" without checking any source — wrong; see `tasks/T-003.md` activity log.)* |
| **Atlas seed** | A seed variant where the Book item behaves as a map/atlas — affects the "book-is-atlas" toggle. |
| **RoomType / MonsterDetail / FloorDropDetail** | The three independent per-room classification axes in the dungeon tracker (34 / 32 / 9 possible values respectively — see `domain.md` § 4.6). |
| **Broadcast window** | A separate, non-interactive window sized/positioned for OBS capture — see `contracts.md` § 2 entry 1. |
| **Reminder** | A spoken and/or visual nudge triggered by tracked state changes, grouped into 7 categories (see `domain.md` § 4.10). |
| **Autosave / manual save / finished save** | The three save-file triggers — see `data-model.md` § 1. |
| **Parity** | Shorthand used throughout this project's docs for "matches the reference app's (`Zelda1RandoTools`) behavior" — the acceptance bar for this clone, per `domain.md`. |
| **Reference app** | `Zelda1RandoTools` — the pinned, read-only fork this project clones feature-by-feature. Never developed further; see `playbook/workspace.manifest.md`. |

## Update-this-doc-when

Add a term here whenever a new domain concept is introduced in `domain.md` or
in code and isn't self-explanatory from its name alone.
