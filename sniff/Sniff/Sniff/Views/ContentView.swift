//
//  ContentView.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//

import SwiftUI

struct ContentView: View {
	@Environment(DataModel.self) var dataModel

	var body: some View {
		NavigationStack {
			switch dataModel.displayMode {
			case .choosePaths:
				ChoosePathsView()
			case let .comparison(comparison):
				ComparisonView(comparison: comparison)
			}
		}
	}
}

#Preview {
	ContentView()
		.environment(DataModel())
}
