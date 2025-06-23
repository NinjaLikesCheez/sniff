// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "swiff",
	platforms: [.macOS(.v15)],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.1"),
		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1"),
		.package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.59.1"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.executableTarget(
			name: "swiff",
			dependencies: [
				"SwiffLibrary",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			]
		),
		.target(
			name: "SwiffLibrary",
			dependencies: [
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftParser", package: "swift-syntax"),
			]
		),
	]
)
