// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "PremierLeagueBar",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "Vendor/DynamicNotchKit")
    ],
    targets: [
        .executableTarget(
            name: "PremierLeagueBar",
            dependencies: ["DynamicNotchKit"],
            exclude: ["Info.plist"],
            resources: [.process("Resources")]
        )
    ]
)
