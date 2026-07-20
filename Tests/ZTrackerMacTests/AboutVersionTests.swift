import Testing
import Foundation
@testable import ZTrackerMac

/// T-163 — the About footer's version string + project link.
@MainActor
struct AboutVersionTests {
    @Test("appVersion is a non-empty 'v'-prefixed string")
    func versionFormat() {
        let v = SettingsPanelView.appVersion
        #expect(v.hasPrefix("v"))
        #expect(v.count > 1)   // "v" + something (a version, or "dev" when unbundled)
    }

    @Test("project URL is a well-formed https link")
    func projectURL() {
        #expect(SettingsPanelView.projectURL.scheme == "https")
        #expect(SettingsPanelView.projectURL.host?.contains("github.com") == true)
    }
}
