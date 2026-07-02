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
            resources: [
                // Third-party assets, MIT-licensed -- see /NOTICE.md.
                .copy("Resources/s_icon_overworld_strip39.png"),
                .copy("Resources/s_map_overworld_vanilla_strip8.png")
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
