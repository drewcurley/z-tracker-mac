import Combine
import Foundation
import Sparkle

/// In-place auto-update via Sparkle 2 (T-211). Wraps `SPUStandardUpdaterController`, which owns
/// the updater and Sparkle's standard user-facing UI (progress, release notes, install prompt),
/// and exposes just what the app's menu/banner need: `checkForUpdates()` and whether a check is
/// currently allowed.
///
/// Free path: updates are authenticated by an **EdDSA** signature (public key in Info.plist,
/// private key in the release machine's Keychain) — independent of Apple notarization. The feed
/// is a per-architecture appcast (`SUFeedURL`, injected at bundle time) so the dedicated arm64 /
/// Intel builds each update to their own native binary.
@MainActor
final class SparkleUpdaterController: ObservableObject {
    private let controller: SPUStandardUpdaterController
    /// Sparkle gates checks (e.g. while one is already running); the menu item follows this.
    @Published var canCheckForUpdates = false

    init() {
        // `startingUpdater: true` starts the updater immediately; nil delegates use Sparkle's
        // standard behavior + UI. Scheduled/automatic checks are off (Info.plist
        // `SUEnableAutomaticChecks = NO`) — the app drives checks from its own banner/menu.
        controller = SPUStandardUpdaterController(startingUpdater: true,
                                                  updaterDelegate: nil,
                                                  userDriverDelegate: nil)
        controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .assign(to: &$canCheckForUpdates)
    }

    /// Check the appcast now and, if a newer signed build exists, run Sparkle's
    /// download → verify → replace-in-place → relaunch flow (its own UI shows progress).
    func checkForUpdates() {
        controller.updater.checkForUpdates()
    }
}
