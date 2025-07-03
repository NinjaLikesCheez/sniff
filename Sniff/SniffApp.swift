//
//  SniffApp.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//

import SwiftUI

@main
struct SniffApp: App {
	@State private var model = DataModel()

	var body: some Scene {
		WindowGroup {
			NavigationStack {
				switch model.displayMode {
				case .choosePaths:
					ChoosePathsView()
				case let .comparison(comparison):
					ComparisonView(comparison: comparison)
				}
			}
			.environment(model)
			.frame(minWidth: Constants.minWidth, maxWidth: .infinity, minHeight: Constants.minHeight, maxHeight: .infinity)
		}
	}
}
