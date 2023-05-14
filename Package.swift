// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Asynchronous Interaction Coordinator",
    platforms: [.iOS(.v12), .macCatalyst(.v15), .macOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Interaction-Queue",
            targets: ["InteractionQueue"]
        ),
        .library(
            name: "Async-Operations",
            targets: ["AsyncOperation"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "ConcurrentKVO", url: "https://github.com/rule-of-72/ConcurrentKVO", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "InteractionQueue",
            dependencies: ["AsyncOperation"]
        ),
        .target(
            name: "AsyncOperation",
            dependencies: [
                .product(name: "ConcurrentKVO", package: "ConcurrentKVO"),
            ]
        ),
        .testTarget(
            name: "InteractionQueueTests",
            dependencies: ["InteractionQueue"]
        ),
    ]
)
