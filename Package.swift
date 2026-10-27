// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PressePapiers",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "PressePapiers", path: "Sources/PressePapiers")
    ]
)
