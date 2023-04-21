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
        .package(name: "KeychainSwift", url: "https://github.com/evgenyneu/keychain-swift.git", from: "19.0.0"),
        .package(name: "CombineExt", url: "https://github.com/CombineCommunity/CombineExt.git", from: "1.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", .upToNextMajor(from: "6.0.0"))
    ],
    targets: [
        .target(
            name: "NoughtyEnvironment",
            dependencies: [
                "KeychainSwift",
                "CombineExt",
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ],
            path: "Sources"
        )
    ],
    swiftLanguageVersions: [.v5]
)
