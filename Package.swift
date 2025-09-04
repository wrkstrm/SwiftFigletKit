// swift-tools-version:6.1
import PackageDescription

let package: Package = .init(
  name: "SwiftFigletKit",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
    .tvOS(.v16),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "SwiftFigletKit", targets: ["SwiftFigletKit"]),
    .executable(name: "swift-figlet-cli", targets: ["SwiftFigletCLI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
  ],
  targets: [
    .target(
      name: "SwiftFigletKit",
      dependencies: [],
      resources: [
        .copy("Resources/Fonts")
      ],
      swiftSettings: [
        .define("SIMULATOR", .when(platforms: [.iOS], configuration: .debug))
      ],
    ),
    .executableTarget(
      name: "SwiftFigletCLI",
      dependencies: [
        "SwiftFigletKit",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .testTarget(
      name: "SwiftFigletKitTests",
      dependencies: ["SwiftFigletKit"],
      resources: [
        .copy("testFonts")
      ]
    ),
  ],
)
