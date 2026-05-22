// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SafeCodable",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "SafeCodable", targets: ["SafeCodable"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SafeCodable",
            dependencies: [],
            path: "SafeCodable/Sources/SafeCodable"
        ),
        .testTarget(
            name: "SafeCodableTests",
            dependencies: ["SafeCodable"],
            path: "SafeCodable/Tests/SafeCodableTests"
        )
    ]
)
