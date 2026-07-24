import Foundation

/// Dotted-numeric app version comparison for the update check (T-174). Handles the
/// forms that actually appear: `"0.8.0"`, `"v0.8"`, `"0.8.0-beta"` (pre-release
/// suffix ignored for ordering), missing components treated as 0. Non-numeric junk
/// parses to nothing and never claims an update.
public struct AppVersion: Comparable, Equatable, Sendable, CustomStringConvertible {
    public let components: [Int]

    /// Parse a version string, tolerating a leading `v` and a `-suffix`/`+build`.
    /// Returns nil if there's no leading numeric component at all.
    public init?(_ raw: String) {
        var s = raw.trimmingCharacters(in: .whitespaces)
        if s.first == "v" || s.first == "V" { s.removeFirst() }
        // Drop a pre-release / build suffix ("-beta", "+ci") — we order on the
        // numeric core only.
        if let cut = s.firstIndex(where: { $0 == "-" || $0 == "+" }) { s = String(s[..<cut]) }
        let parts = s.split(separator: ".", omittingEmptySubsequences: false)
        let nums = parts.map { Int($0) }
        guard let first = nums.first, first != nil else { return nil }
        // Any non-numeric component (e.g. "0.x.1") is treated as 0 rather than
        // failing the whole parse.
        components = nums.map { $0 ?? 0 }
    }

    public var description: String { components.map(String.init).joined(separator: ".") }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let n = max(lhs.components.count, rhs.components.count)
        for i in 0..<n {
            let l = i < lhs.components.count ? lhs.components[i] : 0
            let r = i < rhs.components.count ? rhs.components[i] : 0
            if l != r { return l < r }
        }
        return false
    }

    /// Whether `latest` is a strictly newer release than `current`. Either being
    /// unparseable → `false` (never nag on garbage input).
    public static func isNewer(latest: String, than current: String) -> Bool {
        guard let l = AppVersion(latest), let c = AppVersion(current) else { return false }
        return l > c
    }
}
