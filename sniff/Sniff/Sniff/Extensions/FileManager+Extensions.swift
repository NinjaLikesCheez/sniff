//
//  FileManager+Extensions.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//
import Foundation

extension FileManager {
	func isDirectory(_ path: URL) -> Bool {
		var isDirectory: ObjCBool = false

		return fileExists(atPath: path.path, isDirectory: &isDirectory) && isDirectory.boolValue
	}

	public func filteredContents(
			of path: URL,
			properties: [URLResourceKey]? = nil,
			recursive: Bool = true,
			filter: (URL) throws -> Bool
		) rethrows -> [URL] {
			guard recursive else {
				let contents =
					(try? contentsOfDirectory(
						at: path,
						includingPropertiesForKeys: properties
					)) ?? []

				return try contents.filter(filter)
			}

			guard let enumerator = enumerator(at: path, includingPropertiesForKeys: properties)
			else {
				return []
			}

			return try enumerator.compactMap {
				if case let url as URL = $0 {
					return url
				}

				return nil
			}
			.filter { try filter($0) }
		}
}
