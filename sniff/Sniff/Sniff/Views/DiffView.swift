//
//  DiffView.swift
//  Sniff
//
//  Created by ninji on 25/06/2025.
//

import SwiftUI

struct DiffView: View {
	var diff: FrameworkDiff

	var body: some View {
		ScrollView {
			// TODO: this identity is niet goed broer
			ForEach(diff.attributedLines) { line in
				HStack(alignment: .center) {
					Text("\(line.lineNumber)")
					Text(line.text)
				}
				.frame(maxWidth: .infinity, alignment: .leadingFirstTextBaseline)
				.background {
					switch line.changeStatus {
					case .added: Color.green.opacity(0.18)
					case .removed: /*Color.red.opacity(0.18)*/ Color.clear // removals don't appear to be working :/
					case .unchanged: Color.clear
					}
				}
			}
		}
	}

	func tint(for line: String) -> Color {
		switch changeStatus(for: line) {
		case .added:
				.green
		case .removed:
				.red
		case .same:
				.clear
		}
	}

	enum ChangeStatus {
		case added
		case removed
		case same
	}

	func changeStatus(for line: String) -> ChangeStatus {
		let insertions = diff.difference.insertions.filter { insertion in
			switch insertion {
			case .insert(offset: _, element: let inserted, associatedWith: _):
				return inserted == line
			default: return false
			}
		}

		guard insertions.isEmpty else {
			return .added
		}

		let removals = diff.difference.insertions.filter { insertion in
			switch insertion {
			case .remove(offset: _, element: let removed, associatedWith: _):
				return removed == line
			default: return false
			}
		}

		guard removals.isEmpty else {
			return .removed
		}

		return .same
	}
}

