// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-observation",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "ObservationPolyfillCore",
      targets: ["ObservationPolyfillCore"]
    ),
    .library(
      name: "ObservationPolyfill",
      targets: ["ObservationPolyfill"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.6.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"605.0.0"),
  ],
  targets: [
    .target(
      name: "ObservationPolyfill",
      dependencies: [
        "ObservationPolyfillCore",
        "ObservationPolyfillMacros",
      ]
    ),
    .target(
      name: "ObservationPolyfillCore",
      dependencies: [
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
      ]
    ),
    .macro(
      name: "ObservationPolyfillMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "ObservationPolyfillTests",
      dependencies: ["ObservationPolyfill"]
    ),
    .testTarget(
      name: "ObservationPolyfillMacrosTests",
      dependencies: [
        "ObservationPolyfillMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    ),
  ],
  swiftLanguageModes: [.v5]
)

#if !os(Windows)
  // Add the documentation compiler plugin if possible
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif

for target in package.targets {
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings?.append(contentsOf: [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ImmutableWeakCaptures"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  ])
}
