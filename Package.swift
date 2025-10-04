// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AITextAgent",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "AITextAgent",
            targets: ["AITextAgent"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AITextAgent",
            dependencies: []
        )
    ]
)
