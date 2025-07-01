//
//  SDKView.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//

import SwiftUI
import Observation


struct SDKView: View {
	@Environment(DataModel.self) var dataModel

	@Binding var comparison: XcodeComparison.SDKComparison?
	@Binding var selection: Xcode.Framework

	var body: some View {
		Self._printChanges()

		return Group {
			if let comparison {
				List(comparison.changes, selection: $selection) { change in
					HStack {
						Text(change.name)

						// Change status label will go here
						switch change.change {
						case .added:
							ChangeLabel("Added", tint: .green)
						case .modified:
							ChangeLabel("Modified", tint: .blue)
						case .removed:
							ChangeLabel("Removed", tint: .red)
						case .unchanged:
							EmptyView()
						}
					}
					.contextMenu {
						Button("Open in Finder") {
							NSWorkspace.shared.activateFileViewerSelecting([change.framework.path])
						}
					}
					.tag(change.framework)
				}
			} else {
				ProgressView("Parsing Frameworks...")
			}
		}
	}
}

