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
            dependencies: ["TrackerCore"]
        ),
        .testTarget(
            name: "TrackerCoreTests",
            dependencies: ["TrackerCore"]
        )
    ]
)
