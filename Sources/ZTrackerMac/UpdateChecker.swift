import Foundation
import Observation
import TrackerCore

/// Check-on-launch update notice (T-174). Does a single unauthenticated GET to the
/// project's GitHub "latest release" endpoint, compares the tag to the running
/// bundle version, and — only if a strictly newer release exists — publishes it for
/// a dismissible banner. Fails silently (offline, rate-limited, malformed): no error
/// UI, it simply doesn't nag.
///
/// Privacy: the URL is hard-coded to this project's repo, no query parameters, and no
/// data about the user is sent. It's gated on `TrackerOptions.checkForUpdatesOnLaunch`.
@Observable
@MainActor
final class UpdateChecker {
    /// A newer release, when one is found (else nil). Drives the banner.
    struct Available: Equatable { let version: String; let url: URL }
    private(set) var available: Available?
    /// Set once a check has completed (success or failure), so the banner logic can
    /// tell "no update" from "haven't looked yet".
    private(set) var didCheck = false

    /// The "latest release" API for this project. GitHub returns the most recent
    /// non-draft, non-prerelease release here.
    static let latestReleaseAPI = URL(string:
        "https://api.github.com/repos/drewcurley/z-tracker-mac/releases/latest")!

    private let currentVersion: String
    private let session: URLSession

    init(currentVersion: String = UpdateChecker.bundleVersion,
         session: URLSession = .shared) {
        self.currentVersion = currentVersion
        self.session = session
    }

    /// The running app's short version (`CFBundleShortVersionString`), or `"dev"`
    /// when unbundled — `AppVersion` treats `"dev"` as unparseable, so an unbundled
    /// run never shows an update notice.
    static var bundleVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "dev"
    }

    /// Run the check if the option is on and it hasn't run yet. Safe to call from
    /// `.task`/`.onAppear`; never throws.
    func checkIfEnabled(_ options: TrackerOptions) async {
        guard options.checkForUpdatesOnLaunch, !didCheck else { return }
        await check()
    }

    /// Fetch + compare once. Any failure leaves `available` nil.
    func check() async {
        didCheck = true
        var request = URLRequest(url: Self.latestReleaseAPI)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        guard
            let (data, response) = try? await session.data(for: request),
            let http = response as? HTTPURLResponse, http.statusCode == 200,
            let release = try? JSONDecoder().decode(GitHubRelease.self, from: data)
        else { return }
        // A release page is nice-to-have; fall back to the repo releases page.
        let url = release.htmlURL.flatMap(URL.init(string:))
            ?? URL(string: "https://github.com/drewcurley/z-tracker-mac/releases")!
        if AppVersion.isNewer(latest: release.tagName, than: currentVersion) {
            available = Available(version: AppVersion(release.tagName)?.description ?? release.tagName,
                                  url: url)
        }
    }

    func dismiss() { available = nil }

    private struct GitHubRelease: Decodable {
        let tagName: String
        let htmlURL: String?
        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }
    }
}
