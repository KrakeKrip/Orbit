import Foundation

enum TempDir {
    static func make() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("orbit-native-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Removes only the unique temp directory this test created.
    static func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
