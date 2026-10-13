// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Orbit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "OrbitCore", targets: ["OrbitCore"]),
        .executable(name: "OrbitMac", targets: ["OrbitMac"]),
    ],
    targets: [
        .target(name: "OrbitCore"),
        .executableTarget(
            name: "OrbitMac",
            dependencies: ["OrbitCore"]
        ),
        .testTarget(
            name: "OrbitCoreTests",
            dependencies: ["OrbitCore"]
        ),
    ]
)
