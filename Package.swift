// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "DeskCore", platforms: [.macOS("27.0"), .iOS("27.0")],
  products: [.library(name: "DeskCore", targets: ["DeskCore"])],
  targets: [
    .target(name: "DeskCore", path: "Sources/Core"),
    .testTarget(name: "DeskCoreTests", dependencies: ["DeskCore"], path: "Tests/Core"),
  ])
