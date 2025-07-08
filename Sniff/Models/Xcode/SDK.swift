	//
//  SDK.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//
import Foundation

extension Xcode {
	struct SDK: Hashable, Identifiable {
		var id: URL { path }
		
		let path: URL
		let frameworks: [Framework]
		let frameworksPath: URL

		init(path: URL) {
			self.path = path

			var frameworksPath = path.appending(path: "System")

			if path.lastPathComponent.contains("DriverKit") {
				// DriverKit is a special baby
				frameworksPath = frameworksPath
					.appending(path: "DriverKit")
					.appending(path: "System")
			}

			frameworksPath = frameworksPath
				.appending(path: "Library")
				.appending(path: "Frameworks")

			self.frameworksPath = frameworksPath

			self.frameworks = Self.findFrameworks(in: frameworksPath)
		}

		static func findFrameworks(in path: URL) -> [Framework] {
			FileManager.default
				.filteredContents(
					of: path,
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
