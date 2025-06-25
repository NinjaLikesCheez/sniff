// The Swift Programming Language
// https://docs.swift.org/swift-book
import ArgumentParser
import Foundation
import SwiffLibrary

// TODO: this also needs to support Obj-C headers...

struct SDKOptions: ParsableArguments {
	@Argument(help: "Path to the SDK to compare against")
	var against: URL

	@Argument(help: "Path to the SDK to compare against")
	var to: URL

	@Argument(help: "Output path")
	var output: URL?
}

@main
struct Swiff: ParsableCommand {
	nonisolated static var configuration: CommandConfiguration {
		CommandConfiguration(
			abstract: "A utility for SDK comparison.",
			subcommands: [ListFrameworks.self, DiffFrameworks.self, Available.self]
		)
	}
}

extension URL: @retroactive ExpressibleByArgument {
	public init?(argument: String) {
		self = URL(fileURLWithPath: argument).absoluteURL
	}
}
