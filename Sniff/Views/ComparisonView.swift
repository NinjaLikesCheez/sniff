//
//  ComparisonView.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//

import SwiftUI

extension ComparisonView {
	@Observable
	final class ViewModel {
		let comparison: XcodeComparison

		var platformSelection: Xcode.Platform
		var frameworkSelection: Xcode.Framework {
			didSet {
				parseFrameworkChanges()
			}
		}

		var platforms: [Xcode.Platform]
		var frameworks: [Xcode.Framework] = []

		var sdkComparison: XcodeComparison.SDKComparison?
		var frameworkComparison: XcodeComparison.FrameworkComparison?

		init(comparison: XcodeComparison) {
			self.comparison = comparison

			let initialPlatform = comparison.to.platforms.first(where: { $0.type == .iOS })!
			self.platformSelection = initialPlatform
			self.frameworkSelection = initialPlatform.sdk.frameworks.first!

			platforms = comparison.to.platforms.sorted(by: { $0.name < $1.name })
		}

		func parseSDKChanges() {
			sdkComparison = nil

			let againstFrameworks = comparison.against.platform(for: platformSelection.type).sdk.frameworks.reduce(into: [String: Xcode.Framework](), { $0[$1.name] = $1 })
			let toFrameworks = platformSelection.sdk.frameworks.reduce(into: [String: Xcode.Framework](), { $0[$1.name] = $1 })

			Task {
				sdkComparison = .init(against: againstFrameworks, to: toFrameworks)
			}
		}

		func parseFrameworkChanges() {
			Task {
				frameworkComparison = .init(
					against: comparison.against.platform(for: platformSelection.type).sdk.findFramework(named: frameworkSelection.name),
					to: frameworkSelection
				)
			}
		}
	}
}

struct ComparisonView: View {
	@Environment(DataModel.self) var dataModel

	@State private var viewModel: ViewModel
	@State private var splitViewVisibility: NavigationSplitViewVisibility = .automatic

	init(comparison: XcodeComparison) {
		viewModel = .init(comparison: comparison)
	}

	var body: some View {
		NavigationSplitView(columnVisibility: $splitViewVisibility) {
			List(viewModel.platforms, selection: $viewModel.platformSelection) { platform in
				Label(platform.name, systemImage: platform.systemImage)
					.tag(platform)
					.onChange(of: viewModel.platformSelection) { _, _ in
						// reset frameworks selection on platform change
						viewModel.frameworkSelection = viewModel.platformSelection.sdk.frameworks.first!
						viewModel.parseSDKChanges()
					}
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
			.onAppear {
				viewModel.parseSDKChanges()
			}
		} content: {
			SDKView(
				comparison: $viewModel.sdkComparison,
				selection: $viewModel.frameworkSelection
			)
		} detail: {
			if viewModel.sdkComparison != nil {
				DiffView(comparison: $viewModel.frameworkComparison)
			} else {
				ContentUnavailableView("Select a Framework", systemImage: "briefcase")
			}
		}
		.navigationSplitViewStyle(.automatic)
	}
}
