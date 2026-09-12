import Testing
@testable import ZTrackerMac

@Suite("Sponsor plug (T-225)")
struct SponsorPlugTests {
    @Test("the sponsor URL points at the author's GitHub Sponsors page")
    func url() {
        #expect(Sponsor.url.absoluteString == "https://github.com/sponsors/drewcurley")
    }

    @Test("the post-run prompt is capped to about once a week")
    func interval() {
        #expect(Sponsor.minInterval == 7 * 24 * 60 * 60)
    }
}
