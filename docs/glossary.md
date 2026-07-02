# Glossary — z-tracker-mac

Terms used across this project's docs and (eventually) code. Sourced from the
reference app's own terminology (`Zelda1RandoTools`) so that porting
discussions stay unambiguous — see `domain.md` for the full feature context
behind each term.

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
| **Boomstick** | A seed-specific item combination (Bow + Boomerang merged) — affects several toggles (`IsBoomstickSeed`, "Boomstick Book"). |
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
