import Foundation

/// Locates bundled resource files (sprites / atlas PNGs) by **direct file path**, deliberately
/// avoiding SwiftPM's generated `Bundle.module` accessor.
///
/// `Bundle.module` resolves the nested resource bundle via `Bundle(url:)` and `fatalError`s if
/// none of its candidates validate. On **macOS 15 (Sequoia)** that validation rejects the
/// SwiftPM resource bundle (`ZTrackerMac_ZTrackerMac.bundle`) — so the app trapped at launch on
/// the first sprite load (T-202/T-203). The dev machine's newer macOS was lenient, which hid it.
///
/// Reading the file straight off disk sidesteps *all* bundle validation: the resources are
/// physically present under `…/Contents/Resources/ZTrackerMac_ZTrackerMac.bundle/`, so a direct
/// `FileManager` path lookup succeeds wherever the files exist, on every supported OS. Nothing in
/// the app references `Bundle.module` anymore, so its `fatalError` initializer never runs.
enum AppResources {
    /// The SwiftPM resource-bundle folder name (from the package/target names).
    private static let bundleFolder = "ZTrackerMac_ZTrackerMac.bundle"

    /// Anchors a `Bundle(for:)` lookup on the module that owns the resources, so the search
    /// also works from the test runner (where `Bundle.main` is xctest, not the app).
    private final class BundleToken {}

    /// Directories that may directly contain the resource files, in priority order. Composed
    /// from URL properties of already-loaded bundles (`Bundle.main`, `Bundle(for:)`) — never
    /// `Bundle(url:)` on the nested resource folder, which is exactly the call Sequoia rejects.
    private static let searchRoots: [URL] = {
        var roots: [URL] = []
        var seen = Set<String>()
        func add(_ base: URL?, nested: Bool = true) {
            guard let base else { return }
            let url = nested ? base.appendingPathComponent(bundleFolder) : base
            if seen.insert(url.path).inserted { roots.append(url) }
        }
        let token = Bundle(for: BundleToken.self)   // the .app in-app; the .xctest in tests
        // App: …/Contents/Resources/<bundle>. Tests: the resource bundle sits beside the
        // .xctest (token.bundleURL's parent) and/or inside the runner's Resources.
        add(Bundle.main.resourceURL)
        add(token.resourceURL)
        add(token.bundleURL.deletingLastPathComponent())     // sibling of the .app / .xctest
        add(Bundle.main.bundleURL.deletingLastPathComponent())
        add(Bundle.main.bundleURL)
        // Fallbacks: resources flattened directly into a Resources dir (no nested folder).
        add(Bundle.main.resourceURL, nested: false)
        add(token.resourceURL, nested: false)
        return roots
    }()

    /// The URL of a bundled resource file, or `nil` if it isn't present. No `Bundle` validation —
    /// a plain existence check on a composed path.
    static func url(forResource name: String, withExtension ext: String) -> URL? {
        let file = "\(name).\(ext)"
        for root in searchRoots {
            let candidate = root.appendingPathComponent(file)
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        }
        return nil
    }
}
