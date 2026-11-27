// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Sote",
    platforms: [.macOS(.v14)],
    targets: [.executableTarget(name: "Sote", path: "Sources")]
)
