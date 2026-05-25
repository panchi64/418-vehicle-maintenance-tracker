// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Localization",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Localization",
            targets: ["Localization"]
        )
    ],
    targets: [
        .target(
            name: "Localization",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "LocalizationTests",
            dependencies: ["Localization"]
        )
    ]
)
