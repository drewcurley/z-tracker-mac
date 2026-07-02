# Testing — z-tracker-mac

**Status:** scaffold implemented (`tasks/T-002.md`, merged) — `TrackerCoreTests`
is a real, running test target. Feature-level test coverage described below is
still forward-looking (the features themselves don't exist yet).

## Strategy

A native macOS app with no backend and no network surface. The testing pyramid is
narrower than a typical client/server project:

| Level | Tool | What it covers |
|---|---|---|
| Unit | **Swift Testing** (`import Testing`, `@Test`/`@Suite`) — not XCTest, see `docs/decisions/0002-scaffold-decisions.md` | Tracker domain logic — item/location state machine, save/load (de)serialization, overworld routing logic, any pure-function game-state derivation. This is almost all of the app's logic surface, ported from what `Zelda1RandoTools`'s F# core does today (see `domain.md`). Two real examples exist today: `TrackerModelTests`, `SaveDirectoryLocatorTests`. |
| Integration | Swift Testing | Save-file round-trip (write then read back), any local file-system interaction, OBS integration surface if implemented (see `contracts.md`). |
| UI / end-to-end | XCUITest | Golden-path flows: launch app, click through a tracker screen's core gestures, verify on-screen state updates. Swift Testing does not cover UI-level end-to-end tests — XCUITest remains the plan here. Given the "near pixel-perfect" goal, visual/layout regression checks (e.g. snapshot testing of key views) are worth adding once the UI stabilizes — **UNKNOWN — needs human confirmation** whether a snapshot-testing library (e.g. swift-snapshot-testing) will be adopted; not decided yet. |

## Coverage gates

Not yet configured (nothing to gate meaningfully yet — the scaffold has 5
tests over two trivial units). Wire a coverage report into CI
(`swift test --enable-code-coverage`) once the first real feature task lands,
before a hard percentage gate is chosen.

## Test data approach

Given the domain (Zelda 1 Randomizer seeds), test fixtures will likely include:
canned seed/save-file samples for round-trip tests. No production data, no PII,
no external test environment needed — everything is local and deterministic.

## The regression-safety check (`playbook/AGENTS.md` § 7)

Before any commit that touches something documented in `contracts.md` (a save-file
field, a keyboard/mouse gesture mapping, an OBS integration point, a config/startup
option), the change must:
1. Update `contracts.md` (and `api.md`/`data-model.md` as applicable) in the same PR.
2. Be covered by a test at the level that actually guards that contract — a unit
   test alone does not prove a save-file format change is backward-compatible;
   that needs an integration-level round-trip test against an old-format fixture.
3. State in the review artifact: "Regression-safety: contracts touched = …;
   reflected in docs = yes/no; compatibility = backward-compatible | migration at `<path>`."

## Update-this-doc-when

Update this file once the first real feature task adds meaningful coverage —
replace the "nothing to gate yet" note with real coverage numbers and CI job names.
