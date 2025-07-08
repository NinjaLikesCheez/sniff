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
							let url = URL(string: "https://developer.apple.com/documentation/")!.appending(path: change.name)
							NSWorkspace.shared.open(url)
						} label: {
							Label("Open in Browser", systemImage: "safari")
						}

						Button {
							do {
								if let againstFramework = comparison.against.findFramework(named: selection.name) {
									let output = try Process.run("/usr/local/bin/cursor", arguments: ["--diff", againstFramework.path.path(), selection.path.path()])
									print(output.joined(separator: "\n"))
								} else {
									let output = try Process.run("/usr/local/bin/cursor", arguments: [selection.path.path()])
									print(output.joined(separator: "\n"))
								}
							} catch {
								print("Error running 'cursor' command: \(error.localizedDescription)")
							}
						} label: {
							Label("Open Diff in Cursor", systemImage: "notequal")
						}

						Button {
							NSWorkspace.shared.activateFileViewerSelecting([change.framework.path])
						} label: {
							Label("Open in Finder", systemImage: "finder")
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

