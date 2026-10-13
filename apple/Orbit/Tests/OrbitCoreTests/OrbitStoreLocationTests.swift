import Foundation
import Testing
import OrbitCore

@Suite("OrbitStoreLocation")
struct OrbitStoreLocationTests {

    @Test("--store-path <value> form")
    func spaceForm() {
        let resolved = OrbitStoreLocation.resolveStoreURL(
            commandLineArguments: ["OrbitMac", "--store-path", "/tmp/orbit-review/store.sqlite"]
        )
        #expect(resolved.path == "/tmp/orbit-review/store.sqlite")
    }

    @Test("--store-path=<value> form")
    func equalsForm() {
        let resolved = OrbitStoreLocation.resolveStoreURL(
            commandLineArguments: ["OrbitMac", "--store-path=/tmp/orbit-review-2/store.sqlite"]
        )
        #expect(resolved.path == "/tmp/orbit-review-2/store.sqlite")
    }

    @Test("~ in --store-path is expanded to the home directory")
    func tildeExpansion() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let resolved = OrbitStoreLocation.resolveStoreURL(
            commandLineArguments: ["OrbitMac", "--store-path", "~/orbit-store-check/Orbit.store"]
        )
        #expect(!resolved.path.contains("~"))
        #expect(resolved.path == home + "/orbit-store-check/Orbit.store")
    }

    @Test("missing or valueless flag falls back to the default App Support path")
    func fallbackToDefault() {
        let expected = OrbitStoreLocation.defaultStoreURL()
        #expect(
            OrbitStoreLocation.resolveStoreURL(commandLineArguments: ["OrbitMac"]).path
                == expected.path
        )
        #expect(
            OrbitStoreLocation.resolveStoreURL(commandLineArguments: ["OrbitMac", "--store-path"]).path
                == expected.path
        )
        #expect(
            OrbitStoreLocation.resolveStoreURL(commandLineArguments: ["OrbitMac", "--store-path="]).path
                == expected.path
        )
    }

    @Test("default store is App Support/OrbitNative/Orbit.store")
    func defaultPath() {
        let url = OrbitStoreLocation.defaultStoreURL()
        #expect(url.path.hasSuffix("Application Support/OrbitNative/Orbit.store"))
    }
}
