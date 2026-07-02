import Foundation

/// Resolves the macOS-appropriate directory for save files and settings.
///
/// The reference app (`Zelda1RandoTools`) writes next to its own executable —
/// not viable for a signed/notarized macOS app (see docs/data-model.md § 1,
/// resolved by docs/decisions/0002-scaffold-decisions.md). This locator uses
/// `~/Library/Application Support/<bundle identifier>/`, the standard macOS
/// location for a sandboxed or unsandboxed app's own data.
public enum SaveDirectoryLocator {
    /// The bundle identifier used for the Application Support subdirectory.
    /// Kept as a constant here (not read from `Bundle.main`) so it resolves
    /// correctly even when running via `swift run`, which has no bundle.
    public static let bundleIdentifier = "com.drewcurley.ztrackermac"

    /// Returns the directory this app stores save files and settings in,
    /// creating it if it doesn't already exist.
    public static func appSupportDirectory(
        fileManager: FileManager = .default
    ) throws -> URL {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent(bundleIdentifier, isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}
