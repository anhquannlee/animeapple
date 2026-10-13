// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AnimeVsubIOS",
    platforms: [.iOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0"),
    ],
    targets: [
        .target(
            name: "AnimeVsubIOS",
            dependencies: ["SwiftSoup"]
        )
    ]
)
