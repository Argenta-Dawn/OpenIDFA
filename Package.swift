// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenIDFA",
    products: [
        .library(name: "OpenIDFA", targets: ["OpenIDFA"]),
        .library(name: "Identify", targets: ["Identify"]),
    ],
    targets: [
        .target(name: "OpenIDFA", dependencies: [
            "Identify",
        ]),
        .target(name: "Identify"),
        .testTarget(name: "OpenIDFATests", dependencies: ["OpenIDFA"]),
    ]
)
