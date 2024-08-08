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
    .library(name: "SwiftFigletKit", targets: ["SwiftFigletKit"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
      name: "SwiftFigletKit",
      dependencies: [],
      resources: [.copy("Resources")]),
    .testTarget(
      name: "SwiftFigletKitTests",
      dependencies: ["SwiftFigletKit"]),
  ]
)
