// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ZTrackerMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ZTrackerMac", targets: ["ZTrackerMac"])
    ],
    targets: [
        .target(
            name: "TrackerCore"
        ),
        .executableTarget(
            name: "ZTrackerMac",
            dependencies: ["TrackerCore"],
            // Process the whole Resources directory so every sprite (the original
            // MIT third-party atlases per /NOTICE.md, plus the game sprite GIFs the
            // user supplied) is bundled and reachable at the bundle root by name.
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "TrackerCoreTests",
            dependencies: ["TrackerCore"]
        ),
        .testTarget(
            name: "ZTrackerMacTests",
            dependencies: ["ZTrackerMac"]
        )
    ]
)
