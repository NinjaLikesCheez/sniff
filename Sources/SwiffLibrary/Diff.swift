import Foundation
import SwiftParser
import SwiftSyntax

public struct FrameworkDiff {
	public let againstFramework: Framework
	public let toFramework: Framework

	public enum Error: Swift.Error {
		case noSwiftInterface(Framework)
	}

	public init(againstFramework: Framework, toFramework: Framework) throws {
		guard againstFramework.hasSwiftInterface else {
			throw Error.noSwiftInterface(againstFramework)
		}

		guard toFramework.hasSwiftInterface else {
			throw Error.noSwiftInterface(toFramework)
		}

		self.againstFramework = againstFramework
		self.toFramework = toFramework
	}

	public func diff() throws {
		let againstSyntax = try Self.parseSwiftInterface(at: againstFramework.swiftInterface!)
		let toSyntax = try Self.parseSwiftInterface(at: toFramework.swiftInterface!)

		// TODO: the actual diffing...
	}

	private static func parseSwiftInterface(at url: URL) throws -> SourceFileSyntax {
		let contents = try String(contentsOf: url, encoding: .utf8)
		let sourceFile = Parser.parse(source: contents)
		return sourceFile
	}

	// TODO: Add methods for diffing, reporting, etc.
}
