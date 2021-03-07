// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExpandableLabel",
    products: [
        .library(
            name: "ExpandableLabel",
            targets: ["ExpandableLabel"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "ExpandableLabel",
            dependencies: [],
            path: "Classes")
    ],
    swiftLanguageVersions: [.v5]
)
