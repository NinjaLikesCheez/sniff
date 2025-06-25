import ArgumentParser
import Foundation
import SwiffLibrary

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

	@Option(help: "Output path")
	var output: URL?

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

		let matchingChecks = visitor
			.availabilityChecks
			.filter {
				!Set($0.platforms).isDisjoint(with: platformsSet)
			}

		if let output = output {
			let data = matchingChecks.map { $0.decl.description }.joined(separator: "\n")
			try data.write(to: output, atomically: true, encoding: .utf8)
		} else {
			matchingChecks.forEach { check in
				print(check.decl.description)
			}
		}
	}
}
