//
//  DiffView.swift
//  Sniff
//
//  Created by ninji on 25/06/2025.
//

import SwiftUI

struct ExpandableDiff: Identifiable {
	let id = UUID()
	var isExpanded: Bool = false

	var diff: FrameworkDiff.FileDiff

	init(diff: FrameworkDiff.FileDiff) {
		self.diff = diff
	}
}

struct DiffView: View {
	var diff: FrameworkDiff

	@State private var sections: [ExpandableDiff]

	init(diff: FrameworkDiff) {
		self.diff = diff

		do {
			self.sections = try diff.diff().map { ExpandableDiff(diff: $0) }
			print("no of sections: \(self.sections.count)")
		} catch {
			fatalError("error: \(error.localizedDescription)")
		}
	}

	var body: some View {
		List {
			ForEach($sections) { $section in
				DisclosureGroup(
					isExpanded: $section.isExpanded,
					content: {
						switch section.diff.diff {
						case let .diff(snippet):
							SnippetDiffPreview(diff: snippet)
						case let .added(new):
							SnippetDiffPreview(diff: CodeDiff.diff(snippet: new, from: ""))
						case let .removed(old):
							SnippetDiffPreview(diff: CodeDiff.diff(snippet: "", from: old))
						}
					},
					label: {
						HStack {
							Text(section.diff.name)
								.font(.headline)

							switch section.diff.diff {
							case .diff:
								ChangeLabel("Modified", tint: .blue)
							case .added:
								ChangeLabel("Added", tint: .green)
							case .removed:
								ChangeLabel("Removed", tint: .red)
							}
						}
					}
				)
			}
		}
	}
}
