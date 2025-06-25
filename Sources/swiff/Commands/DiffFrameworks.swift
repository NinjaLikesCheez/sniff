import ArgumentParser
import Foundation
import SwiffLibrary

struct DiffFrameworks: ParsableCommand {
	static var configuration: CommandConfiguration {
		CommandConfiguration(
			commandName: "diff-framework",
			abstract: "Diff the framework differences between two SDKs"
		)
	}

	@OptionGroup var sdkOptions: SDKOptions

	@Argument(help: "Name of the framework to diff")
	var frameworkName: String

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
