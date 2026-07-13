// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FeatureFlags",
    platforms: [.iOS("17.0")],
    products: [
        .library(
            name: "FeatureFlags",
            targets: ["FeatureFlags"]),
    ],
    dependencies: [
        .package(name: "FlagGen", path: "../../../flag-gen"),
    ],
    targets: [
        .target(
            name: "FeatureFlags",
            dependencies: ["FlagGen"],
            path: "FeatureFlags"
        ),
    ]
)
