// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VehicleSharing",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VehicleSharing",
            targets: ["VehicleSharing"]
        )
    ],
    targets: [
        .target(
            name: "VehicleSharing"
        ),
        .testTarget(
            name: "VehicleSharingTests",
            dependencies: ["VehicleSharing"]
        )
    ]
)
