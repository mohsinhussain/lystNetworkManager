// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LystNetworkManager",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "LystNetworkManager",
            targets: ["LystNetworkManager"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.2.0")),
        .package(url: "https://github.com/jrendel/SwiftKeychainWrapper", .upToNextMajor(from: "4.0.0")),
        .package(name: "LystModels", url: "https://github.com/mohsinhussain/lystModels.git", .branch("master"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LystNetworkManager",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "SwiftKeychainWrapper", package: "SwiftKeychainWrapper"),
                .product(name: "LystModels", package: "LystModels"),
            ],
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "LystNetworkManagerTests",
            dependencies: ["LystNetworkManager"]),
    ]
)
