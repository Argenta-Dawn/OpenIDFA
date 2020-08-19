// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "OpenIDFA",
	products: [
		.library(name: "OpenIDFA", targets: ["OpenIDFA"]),
	],
	targets: [
		.target(name: "OpenIDFA", path: "Sources"),
		.testTarget(name: "OpenIDFATests", dependencies: ["OpenIDFA"]),
	]
)
