import Testing
import Foundation
@testable import ZTrackerMac

/// Guards the direct-path resource resolver (T-203) that replaced SwiftPM's `Bundle.module`
/// (whose `Bundle(url:)` validation crashed the app at launch on macOS 15 Sequoia).
@Suite("AppResources (direct-path resource loader)")
struct AppResourcesTests {
    @Test("resolves known sprite + atlas resources to real files")
    func resolvesKnownResources() throws {
        // A GIF sprite (GameSprite) and PNG atlases used across the UI — must resolve without
        // going through Bundle.module / Bundle(url:).
        for (name, ext) in [("Rupy", "gif"), ("icons10x10", "png"),
                            ("ow_icons5x9", "png"), ("zelda_items16x16", "png")] {
            let url = try #require(AppResources.url(forResource: name, withExtension: ext),
                                   "missing resource \(name).\(ext)")
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
    }

    @Test("returns nil for a resource that doesn't exist, without trapping")
    func missingResourceIsNil() {
        #expect(AppResources.url(forResource: "definitely-not-a-real-asset", withExtension: "png") == nil)
    }
}
