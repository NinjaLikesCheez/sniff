//
//  Framework.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//
import Foundation

extension XcodeModel {
	struct Framework: Hashable, Identifiable {
		var id: String { name }

		let name: String
		let path: URL
		let swiftInterface: URL?

		public enum Error: Swift.Error {
			case noSwiftInterface
		}

		public init(path: URL) {
			self.name = path.deletingPathExtension().lastPathComponent
			self.path = path

			let modulePath = path
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
	}
}
