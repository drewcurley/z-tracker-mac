import Testing
@testable import TrackerCore

/// T-174 — version comparison for the update check.
@Suite("App version compare (T-174)")
struct AppVersionTests {

    @Test("newer detection across the forms that actually appear")
    func isNewer() {
        #expect(AppVersion.isNewer(latest: "0.9.0", than: "0.8.0"))
        #expect(AppVersion.isNewer(latest: "v0.9", than: "0.8.0"))     // leading v, short form
        #expect(AppVersion.isNewer(latest: "1.0.0", than: "0.8.5"))
        #expect(AppVersion.isNewer(latest: "0.8.1", than: "0.8"))      // 0.8 == 0.8.0 < 0.8.1
        #expect(AppVersion.isNewer(latest: "0.10.0", than: "0.9.0"))   // numeric, not lexical
    }

    @Test("equal or older is never newer")
    func notNewer() {
        #expect(AppVersion.isNewer(latest: "0.8.0", than: "0.8.0") == false)
        #expect(AppVersion.isNewer(latest: "0.8", than: "0.8.0") == false)   // equal
        #expect(AppVersion.isNewer(latest: "0.7.9", than: "0.8.0") == false)
        #expect(AppVersion.isNewer(latest: "v0.8.0", than: "0.8.0") == false)
    }

    @Test("a pre-release suffix is ignored for ordering")
    func prereleaseSuffixIgnored() {
        #expect(AppVersion.isNewer(latest: "0.9.0-beta", than: "0.8.0"))
        #expect(AppVersion.isNewer(latest: "0.8.0-rc1", than: "0.8.0") == false)  // core equal
    }

    @Test("garbage never claims an update")
    func garbageIsSafe() {
        #expect(AppVersion.isNewer(latest: "not-a-version", than: "0.8.0") == false)
        #expect(AppVersion.isNewer(latest: "0.9.0", than: "dev") == false)
        #expect(AppVersion("") == nil)
        #expect(AppVersion("v") == nil)
    }

    @Test("a non-numeric middle component degrades to 0 rather than failing")
    func partialNumeric() {
        #expect(AppVersion("0.x.1")?.components == [0, 0, 1])
    }
}
