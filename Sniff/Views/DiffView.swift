//
//  DiffView.swift
//  Sniff
//
//  Created by ninji on 25/06/2025.
//

import SwiftUI
import Observation

@Observable
final class ExpandableDiff: Identifiable {
	let id = UUID()
	var isExpanded: Bool = false {
		willSet {
			if newValue {
				parseChangeDiff()
			}
		}
	}

	var change: XcodeComparison.FrameworkComparison.FrameworkFile
	var diff: CodeDiff.SnippetDiff? = nil

	init(change: XcodeComparison.FrameworkComparison.FrameworkFile) {
		self.change = change
	}

	func parseChangeDiff() {
		do {
			let toContent = try String(contentsOf: change.path, encoding: .utf8)
			let againstContent = change.against == nil ? "" : try String(contentsOf: change.against!, encoding: .utf8)

			Task {
				switch change.change {
				case .added, .modified:
					diff = CodeDiff.diff(snippet: toContent, from: againstContent)
					print("Finished diff!")
				case .removed:
					diff = CodeDiff.diff(snippet: againstContent, from: toContent)
				case .unchanged:
					// TODO: this is a waste of cycles. Refactor
					diff = CodeDiff.diff(snippet: toContent, from: againstContent)
				}
			}
		} catch {
			print("error loading contents of path: \(error.localizedDescription)")
		}
	}
}

struct DiffView: View {
	@Binding var comparison: XcodeComparison.FrameworkComparison?

	@State private var sections: [ExpandableDiff] = []
	@State private var selection: XcodeComparison.FrameworkComparison.FrameworkFile? = nil

	init(comparison: Binding<XcodeComparison.FrameworkComparison?>) {
		self._comparison = comparison
	}

	var body: some View {
		Group {
			if comparison != nil {
				List {
					ForEach($sections) { $section in
						DisclosureGroup(isExpanded: $section.isExpanded) {
							HStack {
								if let diff = section.diff {
									SnippetDiffPreview(diff: diff)
								} else {
									ProgressView("Parsing File Diff...")
								}
							}
							.frame(maxWidth: .infinity, maxHeight: .infinity)
						} label: {
							HStack {
								Text(section.change.path.lastPathComponent)

								switch section.change.change {
								case .added: ChangeLabel("Added", tint: .green)
								case .removed: ChangeLabel("Removed", tint: .red)
								case .modified: ChangeLabel("Modified", tint: .blue)
								case .unchanged: EmptyView()
								}
							}
						}
					}
				}
			} else if comparison != nil && !sections.isEmpty {
				ProgressView("Loading File List...")
			} else {
				ContentUnavailableView("Select a Framework", systemImage: "briefcase")
			}
		}
		.onChange(of: comparison) { oldValue, newValue in
			guard let comparison else {
				sections = []
				return
			}

			sections = comparison.changes.map { ExpandableDiff(change: $0) }
		}
	}
}

//// TODO: make this good....
//struct DiffView: View {
//	var diff: FrameworkDiff
//
//	@State private var sections: [ExpandableDiff]
//
//	init(diff: FrameworkDiff) {
//		self.diff = diff
//
//		do {
//			self.sections = try diff.diff().map { ExpandableDiff(diff: $0) }
//			print("no of sections: \(self.sections.count)")
//		} catch {
//			fatalError("error: \(error.localizedDescription)")
//		}
//	}
//
//	var body: some View {
//		List {
//			ForEach($sections) { $section in
//				DisclosureGroup(
//					isExpanded: $section.isExpanded,
//					content: {
//						switch section.diff.diff {
//						case let .diff(snippet):
//							SnippetDiffPreview(diff: snippet)
//						case let .added(new):
//							SnippetDiffPreview(diff: CodeDiff.diff(snippet: new, from: ""))
//						case let .removed(old):
//							SnippetDiffPreview(diff: CodeDiff.diff(snippet: "", from: old))
//						}
//					},
//					label: {
//						HStack {
//							Text(section.diff.name)
//								.font(.headline)
//
//							switch section.diff.diff {
//							case .diff:
//								ChangeLabel("Modified", tint: .blue)
//							case .added:
//								ChangeLabel("Added", tint: .green)
//							case .removed:
//								ChangeLabel("Removed", tint: .red)
//							}
//						}
//					}
//				)
//			}
//		}
//	}
//}
