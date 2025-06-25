//
//  ComparisonView.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//

import SwiftUI

/// NOTE: Ensure XcodeComparison.PlatformsComparison.Difference conforms to Identifiable & Hashable for selection to work
struct ComparisonView: View {
	@Environment(DataModel.self) var dataModel

	@State var comparison: XcodeComparison
	@State private var platformSelection: XcodeModel.Platform
	@State private var frameworkSelection: XcodeModel.Framework?
	@State private var splitViewVisibility: NavigationSplitViewVisibility = .automatic

	init(comparison: XcodeComparison) {
		self.comparison = comparison
		self.platformSelection = comparison.to.platforms.first(where: { $0.type == .iOS })!
	}

	var body: some View {
		NavigationSplitView(columnVisibility: $splitViewVisibility) {
			List(comparison.to.platforms.sorted(by: { $0.name < $1.name }), selection: $platformSelection) { platform in
				Label(platform.name, systemImage: platform.systemImage)
					.tag(platform)
			}
			.toolbar {
				ToolbarItem(placement: .principal) {
					Button {
						dataModel.reset()
					} label: {
						Label("Reset", systemImage: "arrow.uturn.backward")
					}
				}
			}
		} content: {
			FrameworksView(
				comparison: .init(
					against: comparison.against.platform(for: platformSelection.type).sdk.frameworks,
					to: platformSelection.sdk.frameworks
				),
				selection: $frameworkSelection
			)
		} detail: {
			if let frameworkSelection {
				DiffView(comparison: $comparison, platform: platformSelection, framework: frameworkSelection)
			} else {
				ContentUnavailableView("Select a Framework", systemImage: "briefcase")
			}
		}
		.navigationSplitViewStyle(.automatic)
	}
}
