// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HasLazyServer",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "HasLazyServer",
            targets: ["HasLazyServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/southkin/FullyRESTful.git", from: "3.0.0"),
//        .package(url: "https://github.com/southkin/FullyRESTful.git", branch: "dev")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "HasLazyServer"),
        .testTarget(
            name: "HasLazyServerTests",
            dependencies: [
                "HasLazyServer",
                .product(name: "FullyRESTful", package: "FullyRESTful")
            ]),
    ]
)

