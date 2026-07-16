// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "TopScore",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "Vendor/DynamicNotchKit")
    ],
    targets: [
        .executableTarget(
            name: "TopScore",
            dependencies: ["DynamicNotchKit"],
            exclude: ["Info.plist"],
            resources: [.process("Resources")]
        )
    ]
)
