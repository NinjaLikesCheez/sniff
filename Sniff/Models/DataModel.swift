//
//  DataModel.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//
import Observation
import Foundation

enum CompareType {
	case against
	case to
}

@Observable
final class DataModel {
	enum DisplayMode {
		case choosePaths
		case comparison
		case loadingFrameworks
	}

	var comparison: XcodeComparison? {
		willSet {
			if newValue == nil {
				UserDefaults.standard.removeObject(forKey: "against")
				UserDefaults.standard.removeObject(forKey: "to")
			} else {
				UserDefaults.standard.set(comparison.against.path, forKey: "against")
				UserDefaults.standard.set(comparison.to.path, forKey: "to")
			}
		}
	}

	var displayMode: DisplayMode

	init() {
		// rehydrate
		if let against = UserDefaults.standard.url(forKey: "against"), let to = UserDefaults.standard.url(forKey: "to") {
			displayMode = .comparison
		} else {
			displayMode = .choosePaths
		}
	}

	func reset() {
		displayMode = .choosePaths
	}

	func parsePlatform(_ platform: platformSelection) -> [XcodeModel.Framework] {
		
	}
}
