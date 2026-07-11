// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "PremierLeagueBar",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/MrKai77/DynamicNotchKit", from: "1.1.0")
    ],
    targets: [
        .executableTarget(
            name: "PremierLeagueBar",
            dependencies: ["DynamicNotchKit"],
            exclude: ["Info.plist"]
        )
    ]
)
