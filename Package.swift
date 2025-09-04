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
    .executable(name: "swiftfiglet", targets: ["SwiftFigletCLI"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
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
      dependencies: ["SwiftFigletKit"]
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
