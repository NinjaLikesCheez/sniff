//
//  Process+Extensions.swift
//  Sniff
//
//  Created by ninji on 08/07/2025.
//
import Foundation

extension Process {
	@discardableResult
	static func run(_ command: String, arguments: [String] = [], directory: URL? = nil) throws -> [String] {
		let pipe = Pipe()
		let process = Process()

		process.executableURL = URL(filePath: "/usr/bin/env")
		process.arguments = [command] + arguments
		process.standardOutput = pipe
		process.standardError = pipe

		if let directory {
			process.currentDirectoryURL = directory
		}

		try process.run()

		let handle = pipe.fileHandleForReading
		let data = handle.readDataToEndOfFile()
		defer { try? handle.close() }
		process.waitUntilExit()

		return String(data: data, encoding: .utf8)?.components(separatedBy: .newlines) ?? []
	}
}
