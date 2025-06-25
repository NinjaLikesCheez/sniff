import ArgumentParser
import Foundation
import SwiffLibrary

struct ListFrameworks: ParsableCommand {
	static var configuration: CommandConfiguration {
		CommandConfiguration(
			commandName: "list-frameworks",
			abstract: "List the framework differences between two SDKs"
		)
	}

	@OptionGroup var sdkOptions: SDKOptions

	func validate() throws {
		let manager = FileManager.default

		guard manager.directoryExists(at: sdkOptions.against) else {
			throw ValidationError(
				"The path to the SDK to compare against does not exist or is not a directory"
			)
		}

		guard manager.directoryExists(at: sdkOptions.to) else {
			throw ValidationError(
				"The path to the SDK to compare to does not exist or is not a directory"
			)
		}
	}

	func run() throws {
		let againstFrameworks = frameworks(at: sdkOptions.against)
		let toFrameworks = frameworks(at: sdkOptions.to)

		let difference = Set(againstFrameworks.keys)
			.symmetricDifference(toFrameworks.keys)
			.compactMap { toFrameworks[$0] }
			.sorted { $0.name < $1.name }

		if let output = sdkOptions.output {
			let encoder = JSONEncoder()
			encoder.outputFormatting = .prettyPrinted
			let data = try encoder.encode(difference)
			try data.write(to: output)
		} else {
			difference.forEach { framework in
				print(
					"\(framework.name)"
				)
			}
		}
	}
}
