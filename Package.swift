// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "NoughtyEnvironment",
    platforms: [.iOS(.v14), .macOS(.v10_15)],
    products: [
        .library(
            name: "NoughtyEnvironment",
            targets: ["NoughtyEnvironment"]
        )
    ],
    dependencies: [
        .package(name: "KeychainSwift", url: "https://github.com/evgenyneu/keychain-swift.git", from: "19.0.0"),
        .package(name: "CombineExt", url: "https://github.com/CombineCommunity/CombineExt.git", from: "1.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/facebook/facebook-ios-sdk", .exact("17.1.0"))
    ],
    targets: [
        .target(
            name: "NoughtyEnvironment",
            dependencies: [
                "KeychainSwift",
                "CombineExt",
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "FacebookBasics", package: "facebook-ios-sdk"),
                .product(name: "FacebookCore", package: "facebook-ios-sdk"),
                .product(name: "FacebookLogin", package: "facebook-ios-sdk")
            ],
            path: "Sources"
        )
    ],
    swiftLanguageVersions: [.v5]
)
