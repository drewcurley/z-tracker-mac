import Testing
import Foundation
@testable import ZTrackerMac

/// T-243 — the voice debug log is opt-in, private, and can't be redirected; the update banner
/// only opens this repo's pages.
@Suite("Security hygiene (T-243)")
struct SecurityHygieneTests {

    private func tempDir() throws -> URL {
        let d = FileManager.default.temporaryDirectory
            .appendingPathComponent("ztracker-sec-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    @Test("the voice log writes nothing unless explicitly enabled")
    func voiceLogOffByDefault() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("voice.log")
        VoiceDebugLog.write("heard=\"secret\"", to: url, enabled: false)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test("when enabled, the voice log is created owner-only (0600)")
    func voiceLogPrivate() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("voice.log")
        VoiceDebugLog.write("hello", to: url, enabled: true)
        VoiceDebugLog.write("world", to: url, enabled: true)
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text == "[voice] hello\n[voice] world\n")
        let perms = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int
        #expect(perms == 0o600)
    }

    @Test("a planted symlink at the log path is refused, not followed")
    func voiceLogRefusesSymlink() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let victim = dir.appendingPathComponent("victim.txt")
        try Data("untouched".utf8).write(to: victim)
        let link = dir.appendingPathComponent("voice.log")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: victim)
        VoiceDebugLog.write("injected", to: link, enabled: true)
        #expect(try String(contentsOf: victim, encoding: .utf8) == "untouched")
    }

    @Test("only HTTPS pages of this repo on github.com are trusted from the releases API")
    func releaseURLValidated() {
        let ok = URL(string: "https://github.com/drewcurley/z-tracker-mac/releases/tag/v1.2.12")!
        #expect(UpdateChecker.trustedReleaseURL(ok) == ok)
        for bad in ["http://github.com/drewcurley/z-tracker-mac/releases",
                    "https://evil.example/drewcurley/z-tracker-mac/releases",
                    "https://github.com/someone-else/z-tracker-mac/releases",
                    "https://github.com.evil.example/drewcurley/z-tracker-mac/",
                    "file:///Applications/Calculator.app"] {
            #expect(UpdateChecker.trustedReleaseURL(URL(string: bad)!) == nil, "\(bad)")
        }
    }
}
