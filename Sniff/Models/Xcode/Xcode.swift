//
//  Xcode.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//
import SwiftUI
import AppKit
import Foundation

struct Xcode {
	let path: URL
	let icon: Image
	let platforms: [Platform]

	enum Error: Swift.Error {
		case notXcode
	}

	init(path: URL) throws(Error) {
		guard path.lastPathComponent.contains("Xcode") && path.pathExtension == "app" && FileManager.default.isDirectory(path) else {
			throw .notXcode
		}

		self.path = path
		self.icon = Self.findIcon(in: path)
		self.platforms = Self.findPlatforms(in: path)
	}

	func platform(for type: Platform.PlatformType) -> Platform {
		platforms.first(where: { $0.type == type })!
	}
}

// MARK: - Finding Utilies
extension Xcode {
	static private func findIcon(in path: URL) -> Image {
		let icns = path
			.appending(path: "Contents")
			.appending(path: "Resources")

		let potentialPaths = ["Xcode.icns", "XcodeBeta.icns"]

		for potentialPath in potentialPaths {
			let path = icns.appending(path: potentialPath)

			do {
				let icns = try ICNS.parse(path)
				if let data = icns.icons.first?.data, let image = NSImage(data: data) {
					return Image(nsImage: image)
				}
			} catch {
				continue
			}
		}

		return Image(systemName: "hammer.circle")
	}

	static private func findPlatforms(in path: URL) -> [Platform] {
		let platformsPath = path
			.appending(path: "Contents")
			.appending(path: "Developer")
			.appending(path: "Platforms")

		return FileManager.default
			.filteredContents(of: platformsPath, recursive: false) { path in
				path.pathExtension == "platform" && !path.lastPathComponent.contains("Simulator")
			}
			.compactMap { Platform(path: $0) }
	}
}

