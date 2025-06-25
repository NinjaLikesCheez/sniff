//
//  Platform.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//

import Foundation

/* 	static func sdks(in path: URL, for platforms: [Platform]) -> [SDK] {
 platforms
 .map { platform in
 let sdkPath = path
 .appending(path: "Contents")
 .appending(path: "Developer")
 .appending(path: "Platforms")
 .appending(path: platform.rawValue)
 .appending(path: "Developer")
 .appending(path: "SDKs")
 .appending(path: "\(platform.pathName).sdk")

 return SDK(path: sdkPath, platform: platform)
 }
 }*/

extension XcodeModel {
	struct Platform: Hashable, Identifiable {
		var id: URL { path }

		let path: URL
		let type: PlatformType
		let sdk: SDK

		init(path: URL) {
			self.path = path
			self.type = PlatformType(rawValue: path.lastPathComponent)!

			let sdkPath = path
				.appending(path: "Developer")
				.appending(path: "SDKs")
				.appending(path: "\(type.pathName).sdk")

			self.sdk = SDK(path: sdkPath)
		}
	}
}

extension XcodeModel.Platform {
	var name: String {
		switch type {
		case .tvOS:
			"tvOS"
		case .driverKit:
			"DriverKit"
		case .iOS:
			"iOS"
		case .macOS:
			"macOS"
		case .watchOS:
			"watchOS"
		case .visionOS:
			"visionOS"
		}
	}

	var systemImage: String {
		switch type {
		case .tvOS:
			"appletv.fill"
		case .driverKit:
			"car.fill"
		case .iOS:
			"iphone"
		case .macOS:
			"macbook"
		case .watchOS:
			"applewatch"
		case .visionOS:
			"vision.pro"
		}
	}

	enum PlatformType: String, Hashable, Identifiable {
		var id: Self { self }

		case tvOS = "AppleTVOS.platform"
		case driverKit = "DriverKit.platform"
		case iOS = "iPhoneOS.platform"
		case macOS = "MacOSX.platform"
		case watchOS = "WatchOS.platform"
		case visionOS = "XROS.platform"

		var pathName: String {
			let dotIndex = rawValue.firstIndex(of: ".")

			return String(rawValue[rawValue.startIndex..<(dotIndex ?? rawValue.endIndex)])
		}
	}
}
