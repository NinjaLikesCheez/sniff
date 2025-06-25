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
		case comparison(XcodeComparison)
	}

	var displayMode: DisplayMode {
		willSet {
			switch newValue {
			case .comparison(let comparison):
				UserDefaults.standard.set(comparison.against.path, forKey: "against")
				UserDefaults.standard.set(comparison.to.path, forKey: "to")
			case .choosePaths:
				UserDefaults.standard.removeObject(forKey: "against")
				UserDefaults.standard.removeObject(forKey: "to")
			}
		}
	}

	init() {
		// rehydrate
		if let against = UserDefaults.standard.url(forKey: "against"), let to = UserDefaults.standard.url(forKey: "to") {
			do {
				displayMode = .comparison(.init(against: try .init(path: against), to: try .init(path: to)))
			} catch {
				displayMode = .choosePaths
			}
		} else {
			displayMode = .choosePaths
		}
	}

	func reset() {
		displayMode = .choosePaths
	}
}
