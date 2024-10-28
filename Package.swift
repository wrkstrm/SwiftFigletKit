// swift-tools-version:5.10
import PackageDescription

let package = Package(
  name: "SwiftFigletKit",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
    .tvOS(.v16),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "SwiftFigletKit", targets: ["SwiftFigletKit"])
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "SwiftFigletKit",
      dependencies: [],
      resources: [.copy("Resources")]
    ),
    .testTarget(
      name: "SwiftFigletKitTests",
      dependencies: ["SwiftFigletKit"]
    ),
  ]
)
