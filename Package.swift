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
    .executable(name: "swift-figlet-doc-gen", targets: ["SwiftFigletDocGen"]),
    .executable(name: "swift-figlet-dedupe", targets: ["SwiftFigletDedupe"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    // DocC plugin enables `swift package generate-documentation`
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
    .package(name: "CommonShell", path: "../common/domain/system/common-shell"),
  ],
  targets: [
    .systemLibrary(
      name: "CZlib",
      pkgConfig: nil,
      providers: [
        .brew(["zlib"]),
        .apt(["zlib1g-dev"]),
      ]
    ),
    .target(
      name: "SwiftFigletKit",
      dependencies: ["CZlib"],
      resources: [
        .copy("Resources/Fonts")
      ],
      swiftSettings: [
        .define("SIMULATOR", .when(platforms: [.iOS], configuration: .debug))
      ],
    ),
    .executableTarget(
      name: "SwiftFigletDedupe",
      dependencies: [
        "SwiftFigletKit",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
    ),
    .executableTarget(
      name: "SwiftFigletDocGen",
      dependencies: [
        "SwiftFigletKit",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
    ),
    .executableTarget(
      name: "SwiftFigletCLI",
      dependencies: [
        "SwiftFigletKit",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "CommonShell", package: "CommonShell"),
      ],
    ),
    .testTarget(
      name: "SwiftFigletKitTests",
      dependencies: ["SwiftFigletKit"],
      resources: [
        .copy("testFonts")
      ],
    ),
  ],
)
