// The Swift Programming Language
// https://docs.swift.org/swift-book
import ArgumentParser
import Foundation
import SwiffLibrary

// TODO: this also needs to support Obj-C headers...

@main
struct Swiff: ParsableCommand {
	nonisolated static var configuration: CommandConfiguration {
		CommandConfiguration(
			abstract: "A utility for SDK comparison.",
			subcommands: [ListFrameworks.self, DiffFrameworks.self, Available.self]
		)
	}
}

struct Available: ParsableCommand {
	static var configuration: CommandConfiguration {
		CommandConfiguration(
			commandName: "available",
			abstract: "List the availability attributes of a framework in the SDK for a given platform/version"
		)
	}

	@Argument(help: "Path to the SDK to check")
	var sdk: URL

	@Argument(help: "Name of the framework to check")
	var frameworkName: String

	@Option(
		name: .customLong("platform"),
		help: "Platform to apply the availability attribute to. You can pass multiple platforms by passing this option multiple times.",
		transform: Platform.init
	)
	var platforms: [Platform] = [.all]

	func validate() throws {
		guard FileManager.default.directoryExists(at: sdk) else {
			throw ValidationError(
				"The path to the SDK does not exist or is not a directory"
			)
		}
	}

	func run() throws {
		let frameworks = frameworks(at: sdk)

		guard let framework = frameworks[frameworkName] else {
			throw ValidationError(
				"The framework \(frameworkName) does not exist in the SDK"
			)
		}

		let interface = try framework.interface()

		let visitor = AvailabilityVisitor()
		visitor.walk(interface)

		print("Found \(visitor.availabilityChecks.count) availability checks")

		let platformsSet = Set(platforms)

		visitor
			.availabilityChecks
			.filter {
				!Set($0.platforms).isDisjoint(with: platformsSet)
			}
			.forEach { check in
				print(check)
			}
	}
}

struct DiffFrameworks: ParsableCommand {
	static var configuration: CommandConfiguration {
		CommandConfiguration(
			commandName: "diff-framework",
			abstract: "Diff the framework differences between two SDKs"
		)
	}

	@Argument(help: "Path to the SDK to compare against")
	var against: URL

	@Argument(help: "Path to the SDK to compare against")
	var to: URL

	@Argument(help: "Name of the framework to diff")
	var frameworkName: String

	func validate() throws {
		let manager = FileManager.default

		guard manager.directoryExists(at: against) else {
			throw ValidationError(
				"The path to the SDK to compare against does not exist or is not a directory"
			)
		}

		guard manager.directoryExists(at: to) else {
			throw ValidationError(
				"The path to the SDK to compare to does not exist or is not a directory"
			)
		}
	}

	func run() throws {
		let againstFrameworks = frameworks(at: against)
		let toFrameworks = frameworks(at: to)

		// Ensure framework exists in both SDKs
		guard let againstFramework = againstFrameworks[frameworkName] else {
			throw ValidationError(
				"The framework \(frameworkName) does not exist in the SDK to compare against"
			)
		}

		guard let toFramework = toFrameworks[frameworkName] else {
			throw ValidationError(
				"The framework \(frameworkName) does not exist in the SDK to compare to"
			)
		}

		let diff = try FrameworkDiff(againstFramework: againstFramework, toFramework: toFramework)
		try diff.diff()
	}
}

struct ListFrameworks: ParsableCommand {
	static var configuration: CommandConfiguration {
		CommandConfiguration(
			commandName: "list-frameworks",
			abstract: "List the framework differences between two SDKs"
		)
	}

	@Argument(help: "Path to the SDK to compare against")
	var against: URL

	@Argument(help: "Path to the SDK to compare against")
	var to: URL

	func validate() throws {
		let manager = FileManager.default

		guard manager.directoryExists(at: against) else {
			throw ValidationError(
				"The path to the SDK to compare against does not exist or is not a directory"
			)
		}

		guard manager.directoryExists(at: to) else {
			throw ValidationError(
				"The path to the SDK to compare to does not exist or is not a directory"
			)
		}
	}

	func run() {
		// First, get a list of all the frameworks in both SDKs
		let againstFrameworks = frameworks(at: against)
		let toFrameworks = frameworks(at: to)

		let difference = Set(againstFrameworks.keys).symmetricDifference(toFrameworks.keys)

		difference
			.compactMap { toFrameworks[$0] }
			.sorted { $0.name < $1.name }
			.forEach { framework in
				print(
					"\(framework.name)"
				)
			}
	}
}

extension URL: @retroactive ExpressibleByArgument {
	public init?(argument: String) {
		self = URL(fileURLWithPath: argument).absoluteURL
	}
}
