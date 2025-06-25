import Foundation
import SwiftParser
import SwiftSyntax

public struct Framework: Hashable, Codable, Sendable {
	public let name: String
	public let path: URL
	public let swiftInterface: URL?

	public enum Error: Swift.Error {
		case noSwiftInterface
	}

	public init(path: URL) {
		self.name = path.deletingPathExtension().lastPathComponent
		self.path = path

		let modulePath =
			path
			.appendingPathComponent("Modules")
			.appendingPathComponent("\(name).swiftmodule")

		// TODO: Support other architectures and platforms?
		let possibleInterfacePaths = [
			modulePath.appendingPathComponent("arm64e-apple-ios.swiftinterface"),
			modulePath.appendingPathComponent("arm64-apple-ios.swiftinterface"),
		]

		var interfacePath: URL? = nil
		for path in possibleInterfacePaths {
			if FileManager.default.fileExists(atPath: path.path) {
				interfacePath = path
				break
			}
		}

		self.swiftInterface = interfacePath
	}

	public var hasSwiftInterface: Bool {
		swiftInterface != nil
	}

	public func interface() throws -> SourceFileSyntax {
		guard let swiftInterface = swiftInterface else {
			throw Error.noSwiftInterface
		}

		return Parser.parse(source: try String(contentsOf: swiftInterface, encoding: .utf8))
	}
}

public func frameworks(at path: URL) -> [String: Framework] {
	FileManager.default.filteredContents(
		of: path,
		properties: [.isDirectoryKey, .isRegularFileKey],
		filter: { $0.pathExtension == "framework" }
	)
	.map { Framework(path: $0) }
	.reduce(into: [String: Framework]()) { partialResult, framework in
		partialResult[framework.name] = framework
	}
}
