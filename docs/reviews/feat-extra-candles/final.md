# Review: feat/extra-candles — final (T-031)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Full cycle warranted: a new
model flag + a state-enum change that touches derivation + save shape. The
mechanic is a deliberate extension the reference does not model; design was
user-confirmed (not guessed) after research showed the reference has no such
option.

## Blockers
- none

## Warnings (fix before next review)
- [ ] The potion overlay reuses the potion-*shop* sprite (`ow_icons5x9` idx 5);
      it reads as a bottle but is a shop icon. If a truer potion sprite is
      wanted, vendor one — the state itself is correct and distinct.
- [ ] The take-any 4-state cycle is always available (not gated on the Extra
      Candles toggle). Harmless — the candle state is just markable regardless;
      matches the user's "add distinct states" ask.

## Suggestions
- none.

## Agent Sign-offs
- [x] Analyst — scope: exactly the user-confirmed Extra Candles design (toggle,
      wood→candle, 4-state take-any). No creep.
- [x] Architect — no security surface. New `extraCandles` model flag; a value-
      only enum change.
- [x] Data Engineer — `TakeAnyHeartState` keeps the reference raw values
      (0/1/2) and adds candle at 3, so old saves load unchanged (2 → potion).
      `compute` counts the wood-sword-cave item as candle (max 1), not sword,
      under the flag — tested both ways. Take-any heart-counting still keys on
      `.takenHeart` only.
- [x] Backend — N/A.
- [x] Frontend — `extraCandles` chrome toggle; a shared `iconOverride(for:)`
      now covers magical-sword→BU and wood→candle; `TakeAnyHeartBox` renders
      the empty-heart background + a potion/candle overlay; `cycledHeart`
      generalized to `allCases.count`.
- [x] UX — the four take-any states are visually distinct while keeping the
      heart shape for orientation, per the user's request; the wood-sword box
      shows a blue candle under the option.
- [x] Test Engineer — 249→250: wood→candle derivation (on/off), 4-state cycle
      both directions, raw-value/back-compat pin (0/1/2 + candle 3, 4 cases).
      On-device: toggle, wood→candle swap, all four take-any states.
- [x] DevOps — no CI/asset change (reuses existing atlas sprites). `swift build`
      (debug+release) + `swift test` clean.
- [x] Review Coordinator — `tasks/T-031.md` completed; INDEX updated; deviation
      recorded in memory `project_extra-candles-deviation`.

## Lens Sign-offs
- [x] Adopter — a real randomizer option the user plays with is now trackable.
- [x] Builder — the enum change is back-compatible and the override/atlas reuse
      kept it small. Other lenses N/A (local feature).

## Regression safety
- Contracts touched: `PlayerComputedStateSummary.compute` gained a defaulted
  `extraCandles` param (old callers unaffected); `TakeAnyHeartState` gained a
  case + renamed 2→`takenPotion` (raw value preserved; all refs updated).
- Full suite 249→250, no regressions. Builds clean (debug + release).

## Out of scope (follow-ons)
- A dedicated potion sprite (vs the potion-shop icon).
