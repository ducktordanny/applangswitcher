// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "AppLangswitcher",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "AppLangswitcher", path: "Sources/AppLangswitcher"),
    ]
)
