// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "VerbaKit",
    platforms: [.macOS(.v27)],
    products: [
        .library(name: "VerbaKit", targets: ["VerbaKit"])
    ],
    targets: [
        .target(name: "VerbaKit"),
        .testTarget(name: "VerbaKitTests", dependencies: ["VerbaKit"]),
    ]
)
