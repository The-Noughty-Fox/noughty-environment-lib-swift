// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "NoughtyEnvironment",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "NoughtyEnvironment",
            targets: ["NoughtyEnvironment"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", .branch("iso")),
        .package(name: "KeychainSwift", url: "https://github.com/evgenyneu/keychain-swift.git", from: "19.0.0")
    ],
    targets: [
        .target(
            name: "NoughtyEnvironment",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "KeychainSwift"
            ],
            path: "Sources"
        )
    ],
    swiftLanguageVersions: [.v5]
)
