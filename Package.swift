// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "PremierLeagueBar",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "DynamicNotchKit"
        ),
        .executableTarget(
            name: "PremierLeagueBar",
            dependencies: ["DynamicNotchKit"],
            exclude: ["Info.plist"]
        )
    ]
)
