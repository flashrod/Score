// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "PremierLeagueBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PremierLeagueBar",
            exclude: ["Info.plist"]
        )
    ]
)
