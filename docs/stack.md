# Stack — z-tracker-mac

**Status:** forward-looking — decided but not yet implemented (`tasks/T-002.md`
covers scaffolding). See `docs/decisions/0001-native-swiftui-over-avalonia-port.md`
for the reasoning behind "native Swift" over reviving the reference app's
existing Avalonia cross-platform build.

| Concern | Choice | Why |
|---|---|---|
| Language | Swift | Native Apple-platform language; explicit project requirement is a native macOS app. |
| UI framework | SwiftUI, with targeted AppKit interop (`NSViewRepresentable`) where SwiftUI can't deliver pixel-exact sprite rendering/scaling | SwiftUI for structure/state-binding productivity; AppKit escape hatch for the "near pixel-perfect," integer-scaled sprite rendering the reference app is explicit about (nearest-neighbor scaling, exact 768/512/256 broadcast-window widths). **UNKNOWN — needs human confirmation:** whether Core Graphics/`NSView` drawing or SpriteKit ends up being the better fit for the sprite-atlas rendering — a decision for `tasks/T-002.md` or a follow-up ADR once a prototype is tried, not decided here. |
| Package manager | Swift Package Manager (SPM) | Ships with Xcode; no third-party toolchain needed. |
| Test runner | XCTest | Standard, ships with Xcode; see `testing.md`. |
| End-to-end / UI test tool | XCUITest | Standard Xcode UI-testing framework. |
| Persistence | Local JSON files (`Codable` structs) in the app's own data directory — no database | Matches the reference app's approach exactly (hand-serialized JSON, no DB); see `data-model.md`. |
| Speech synthesis | `AVSpeechSynthesizer` | macOS-native replacement for the reference app's `System.Speech` synthesis use (spoken reminders). |
| Speech recognition | `SFSpeechRecognizer` (Speech framework) | macOS-native replacement for `System.Speech` recognition (voice-commanded tile marking). Requires microphone + speech-recognition entitlements/usage-description strings — an Architect-hat item for `tasks/T-002.md` or the first feature task that implements it. |
| Gamepad input | `GameController` framework | macOS-native replacement for the reference app's Windows-only `SharpDX.DirectInput`. |
| Cloud provider | N/A | Local desktop app, no backend. |
| Database | N/A | See Persistence above. |
| Authentication | N/A | Single local user, no accounts. |
| Secret manager | N/A | No secrets/credentials of any kind. |
| CI provider | GitHub Actions | Personal repo, no org policy blocking Actions (contrast with the playbook's inherited Azure DevOps default — see `playbook/docs/decisions/0003-z-tracker-mac-workspace-setup.md`). |
| Hosting / distribution | GitHub Releases (signed + notarized `.app`/`.dmg`) | No server hosting needed for a desktop binary; see `deployment.md`. |
| Monitoring | N/A (local desktop app) | No fleet to monitor; crash reporting is a possible future addition, not decided. |

## Minimum deployment target

**UNKNOWN — needs human confirmation.** Not yet decided. Candidates:
recent SwiftUI versions (macOS 14 Sonoma+) give the most modern APIs for a
greenfield project; an older floor (e.g. macOS 13) widens the install base at
the cost of some SwiftUI API availability. Recommend deciding this in
`tasks/T-002.md` when the Xcode project is actually created, not guessing here.

## Third-party dependencies

None planned at bootstrap time. If any SPM package is added later (e.g. a
snapshot-testing library — see `testing.md`), it must be recorded here with
its license and the reason it was chosen, per the Architect's redline on
supply-chain risk (`playbook/.claude/agents/architect.md`).

## Update-this-doc-when

Update this file the moment `tasks/T-002.md` lands and any "UNKNOWN" above
becomes a real, implemented decision (deployment target, sprite-rendering
approach). Update again whenever a new third-party dependency is added.
