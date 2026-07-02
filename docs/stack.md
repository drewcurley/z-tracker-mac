# Stack — z-tracker-mac

**Status:** implemented for the scaffold (`tasks/T-002.md`, merged) — the
table below reflects what actually builds and runs today, not a plan. See
`docs/decisions/0001-native-swiftui-over-avalonia-port.md` for "native Swift"
over reviving the Avalonia build, and `docs/decisions/0002-scaffold-decisions.md`
for the deployment-target/test-framework/sprite-rendering decisions made
while building the scaffold.

| Concern | Choice | Why |
|---|---|---|
| Language | Swift 6 (`swift-tools-version: 6.0`) | Native Apple-platform language; explicit project requirement is a native macOS app. |
| UI framework | SwiftUI, with `Canvas` + `CGImage` cropping planned for sprite rendering (no AppKit interop for v1 — see ADR 0002) | SwiftUI for structure/state-binding productivity; `Canvas` gives pixel-exact, interpolation-disabled drawing for the "near pixel-perfect," integer-scaled sprite rendering the reference app requires, without an AppKit escape hatch unless a future prototype shows `Canvas` can't keep up (ADR 0002). |
| Package manager | Swift Package Manager (SPM) | `Package.swift` at repo root: library target `TrackerCore` + executable target `ZTrackerMac` + test target `TrackerCoreTests`. |
| Test runner | **Swift Testing** (`import Testing`, `@Test`/`@Suite`) — supersedes the originally-planned XCTest for unit tests, see ADR 0002 | Current first-party successor to XCTest for unit-level tests; better parameterized-test ergonomics. |
| End-to-end / UI test tool | XCUITest (not yet used — no UI to test yet) | Swift Testing does not cover UI-level end-to-end tests; XCUITest remains the plan once there's a real UI (see `testing.md`). |
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

**macOS 14 (Sonoma)**, set in `Package.swift` (`platforms: [.macOS(.v14)]`).
Decided in ADR 0002: no installed-base constraint yet (single user, the
developer), so the newest well-established SwiftUI/Observation APIs win.
Revisit if distributing to others with older machines becomes a real need.

## Third-party dependencies

None planned at bootstrap time. If any SPM package is added later (e.g. a
snapshot-testing library — see `testing.md`), it must be recorded here with
its license and the reason it was chosen, per the Architect's redline on
supply-chain risk (`playbook/.claude/agents/architect.md`).

## Update-this-doc-when

Update this file whenever the sprite-rendering approach is actually
implemented and proven out (replace the "planned" `Canvas` note with what's
real), or whenever a new third-party dependency is added.
