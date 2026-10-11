// swift-tools-version:5.9
// ClipCore holds the app's platform-independent logic (search, filtering,
// dedupe, trimming). It depends only on Foundation, so it builds and tests
// on Linux CI as well as on macOS.
import PackageDescription

let package = Package(
    name: "ClipCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ClipCore", targets: ["ClipCore"])
    ],
    targets: [
        .target(name: "ClipCore"),
        .testTarget(name: "ClipCoreTests", dependencies: ["ClipCore"])
    ]
)
