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
						Button {
							NSWorkspace.shared.activateFileViewerSelecting([change.framework.path])
						} label: {
							Label("Open in Finder", systemImage: "finder")
						}

						Button {
							let url = URL(string: "https://developer.apple.com/documentation/")!.appending(path: change.name)
							NSWorkspace.shared.open(url)
						} label: {
							Label("Open in Browser", systemImage: "safari")
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

