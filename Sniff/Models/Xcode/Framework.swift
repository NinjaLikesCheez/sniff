//
//  Framework.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//
import Foundation

extension Xcode {
	struct Framework: Hashable, Identifiable {
		var id: String { name }

		let name: String
		let path: URL

		let diffablePaths: [URL]

		public enum Error: Swift.Error {
			case noDiffablePaths
		}

		public init(path: URL) {
			self.name = path.deletingPathExtension().lastPathComponent
			self.path = path

			let modulePath = path
				.appending(path: "Modules")
				.appending(path: "\(name).swiftmodule")

			let headerPath = path
				.appending(path: "Headers")

			var diffablePaths = FileManager.default.filteredContents(of: modulePath) { path in
				path.pathExtension == "swiftinterface"
			}

			diffablePaths.append(contentsOf: FileManager.default.filteredContents(of: headerPath) { path in
				path.pathExtension == "h"
			})

			self.diffablePaths = diffablePaths
		}
	}
}
