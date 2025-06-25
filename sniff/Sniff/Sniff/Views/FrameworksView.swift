//
//  FrameworksView.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//

import SwiftUI

struct FrameworksView: View {
	var comparison: XcodeComparison.FrameworksComparison
	@Binding var selection: XcodeModel.Framework?

	var sortedFrameworks: [XcodeModel.Framework] {
		comparison.to.sorted(by: { $0.name < $1.name })
	}

	init(comparison: XcodeComparison.FrameworksComparison, selection: Binding<XcodeModel.Framework?>) {
		self.comparison = comparison
		self._selection = selection
	}

	enum ChangeStatus {
		case added
		case removed
		case same
	}

	func changeStatus(for framework: XcodeModel.Framework) -> ChangeStatus {
		let insertions = comparison.difference.insertions.filter { insertion in
			switch insertion {
			case .insert(offset: _, element: let inserted, associatedWith: _):
				return inserted.name == framework.name
			default: return false
			}
		}

		guard insertions.isEmpty else {
			return .added
		}

		let removals = comparison.difference.insertions.filter { insertion in
			switch insertion {
			case .remove(offset: _, element: let removed, associatedWith: _):
				return removed.name == framework.name
			default: return false
			}
		}

		guard removals.isEmpty else {
			return .removed
		}

		return .same
	}

	var body: some View {
		Self._printChanges()
		return List(sortedFrameworks, selection: $selection) { framework in
			HStack {
				Text(framework.name)

				switch changeStatus(for: framework) {
				case .added:
					ChangeLabel("Added", tint: .green)
				case .removed:
					ChangeLabel("Removed", tint: .red)
				case .same:
					EmptyView()
				}
			}
			.tag(framework)
		}
	}
}
