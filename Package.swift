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
    dependencies: [
        // Sparkle 2 — in-place auto-update (T-211). Free path: EdDSA-signed updates,
        // per-arch appcast; notarization is a later drop-in.
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.6"),   // floor past GHSA-3x7w-j75x-ppq5 / GHSA-4v99-qgq9-6pxp (T-243); exact version pinned by Package.resolved
    ],
    targets: [
        .target(
            name: "TrackerCore"
        ),
        .executableTarget(
            name: "ZTrackerMac",
            dependencies: [
                "TrackerCore",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
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
