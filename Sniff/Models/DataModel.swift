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

	var displayMode: DisplayMode

	init() {
		// rehydrate
		if let against = UserDefaults.standard.url(forKey: "against"), let to = UserDefaults.standard.url(forKey: "to") {
			displayMode = .comparison(.init(against: try! .init(path: against), to: try! .init(path: to)))
		} else {
			displayMode = .choosePaths
		}
	}

	func reset() {
		displayMode = .choosePaths
	}
}
