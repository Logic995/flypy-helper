// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FlypyHelper",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "FlypyHelper",
            targets: ["FlypyHelper"]
        )
    ],
    targets: [
        .executableTarget(
            name: "FlypyHelper"
        ),
        .testTarget(
            name: "FlypyHelperTests",
            dependencies: ["FlypyHelper"]
        )
    ]
)
