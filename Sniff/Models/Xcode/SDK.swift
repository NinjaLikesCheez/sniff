//
//  SDK.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//
import Foundation

extension XcodeModel {
	struct SDK: Hashable, Identifiable {
		var id: URL { path }
		
		let path: URL
		let frameworks: [Framework]

		init(path: URL) {
			self.path = path

			self.frameworks = Self.findFrameworks(in: path)
		}

		static func findFrameworks(in path: URL) -> [Framework] {
			FileManager.default
				.filteredContents(
					of: path
						.appending(path: "System")
						.appending(path: "Library")
						.appending(path: "Frameworks"),
					properties: [.isDirectoryKey, .isRegularFileKey],
					recursive: false,
					filter: { $0.pathExtension == "framework" }
				)
				.map { Framework(path: $0) }
		}

		func findFramework(named name: String) -> Framework? {
			frameworks.first { $0.name == name }
		}
	}
}
