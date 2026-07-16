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
                .copy("Resources/ow_icons5x9.png"),
                .copy("Resources/icons3x7.png"),
                .copy("Resources/s_map_overworld_vanilla_strip8.png"),
                .copy("Resources/icons7x7.png"),
                .copy("Resources/icons8x16.png"),
                .copy("Resources/icons10x10.png"),
                .copy("Resources/zelda_items16x16.png"),
                .copy("Resources/all-items-hud-pixels1.png"),
                .copy("Resources/all-items-hud-pixels1-worse.png"),
                .copy("Resources/icons8x8.png"),
                .copy("Resources/new_icons13x9.png"),
                .copy("Resources/zelda_bosses16x16.png"),
                .copy("Resources/audio")
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
