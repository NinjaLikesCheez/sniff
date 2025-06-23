import Foundation

extension FileManager {
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

	public func directoryExists(at url: URL) -> Bool {
		var isDirectory = ObjCBool(false)
		let result = fileExists(atPath: url.absoluteURL.path, isDirectory: &isDirectory)

		return result && isDirectory.boolValue
	}
}
