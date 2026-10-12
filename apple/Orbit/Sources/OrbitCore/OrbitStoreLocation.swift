import Foundation

/// Centralized store locations and launch-argument resolution.
/// The store path is documented in apple/Orbit/README.md; every override goes through this type.
public enum OrbitStoreLocation {
    /// Default persistent store: `~/Library/Application Support/OrbitNative/Orbit.store`.
    public static func defaultStoreURL(fileManager: FileManager = .default) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support", isDirectory: true)
        return base
            .appendingPathComponent("OrbitNative", isDirectory: true)
            .appendingPathComponent("Orbit.store")
    }

    /// Resolves the store URL from launch arguments.
    /// Supported forms: `--store-path <path>` and `--store-path=<path>`; `~` is expanded.
    /// Falls back to `defaultStoreURL()` when the flag is absent, empty, or has no value.
    public static func resolveStoreURL(
        commandLineArguments arguments: [String],
        fileManager: FileManager = .default
    ) -> URL {
        let flag = "--store-path"
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            if argument == flag {
                let next = index + 1
                if next < arguments.count, !arguments[next].trimmingCharacters(in: .whitespaces).isEmpty {
                    return storeURL(at: arguments[next])
                }
                break
            }
            if argument.hasPrefix("\(flag)=") {
                let value = String(argument.dropFirst("\(flag)=".count))
                if !value.trimmingCharacters(in: .whitespaces).isEmpty {
                    return storeURL(at: value)
                }
                break
            }
            index += 1
        }
        return defaultStoreURL(fileManager: fileManager)
    }

    private static func storeURL(at path: String) -> URL {
        let expanded = (path as NSString).expandingTildeInPath
        return URL(fileURLWithPath: expanded, isDirectory: false).standardizedFileURL
    }
}
