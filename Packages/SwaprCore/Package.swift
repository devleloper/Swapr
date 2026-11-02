// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwaprCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SwaprCore", targets: ["SwaprCore"])
    ],
    targets: [
        .target(name: "SwaprCore"),
        .testTarget(name: "SwaprCoreTests", dependencies: ["SwaprCore"])
    ]
)
