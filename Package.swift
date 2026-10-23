// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Clippo",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Clippo",
            path: "Sources/Clippo",
            swiftSettings: [.unsafeFlags(["-Osize"])]
        )
    ]
)
