// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "ScreenBuddy",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "ScreenBuddy", path: "Sources/ScreenBuddy")
    ]
)
