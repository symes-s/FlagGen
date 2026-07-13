// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "FlagGen",
    platforms: [.iOS("17.0"), .macOS("10.15"), .watchOS("10.0")],
    products: [
        .library(
            name: "FlagGen",
            targets: ["FlagGen"]),
        .plugin(
            name: "GenerateFeatureFlags",
            targets: ["GenerateFeatureFlagsPlugin"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FlagGen",
            dependencies: [],
            path: "FlagGen",
            exclude: [
              "Script/ScriptMain.swift",
            ],
            plugins: []
        ),
        .testTarget(
          name: "FlagGenTests",
          dependencies: [
            "FlagGen",
          ],
          plugins: []
        ),
        .plugin(
            name: "GenerateFeatureFlagsPlugin",
            capability: .command(
                intent: .custom(
                    verb: "generate-feature-flags",
                    description: "Generates Features.plist and Generated/Enums/FeatureFlagsEnum.swift from a FeatureFlags target's @FeatureFlagToggle / @FeatureFlagEnum declarations."
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Writes the generated Features.plist and Generated/Enums/FeatureFlagsEnum.swift into this package.")
                ]
            ),
            path: "Plugins/GenerateFeatureFlagsPlugin"
        ),
    ]
)
