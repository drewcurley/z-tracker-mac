import Foundation
import Testing
@testable import TrackerCore

@Suite("SaveDirectoryLocator")
struct SaveDirectoryLocatorTests {
    @Test("resolves to Application Support / bundle identifier and creates it")
    func resolvesAndCreatesDirectory() throws {
        let fileManager = FileManager.default
        let directory = try SaveDirectoryLocator.appSupportDirectory(fileManager: fileManager)

        #expect(directory.path.contains("Application Support"))
        #expect(directory.lastPathComponent == SaveDirectoryLocator.bundleIdentifier)

        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory)
        #expect(exists)
        #expect(isDirectory.boolValue)
    }

    @Test("is idempotent across repeated calls")
    func idempotent() throws {
        let first = try SaveDirectoryLocator.appSupportDirectory()
        let second = try SaveDirectoryLocator.appSupportDirectory()
        #expect(first == second)
    }
}
