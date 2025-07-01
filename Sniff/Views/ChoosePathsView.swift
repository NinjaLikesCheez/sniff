//
//  ChoosePathsView.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct ChoosePathsView: View {
	@Environment(DataModel.self) var dataModel

	@State private var against: Xcode?
	@State private var to: Xcode?

	var body: some View {
		HStack {
			againstSection

			toSection
		}

		VStack {
			Button {
				let toCopy = to
				let againstCopy = against

				to = againstCopy
				against = toCopy
			} label: {
				Label("Swap", systemImage: "rectangle.2.swap")
			}
			.disabled(against == nil && to == nil)

			Button {
				guard let against, let to else { return }
				dataModel.displayMode = .comparison(.init(against: against, to: to))
			} label: {
				Label("Compare", systemImage: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill")
			}
			.disabled(against == nil || to == nil)
		}
		.padding()
	}

	var againstSection: some View {
		VStack {
			against?.icon
			Text(against?.path.path() ?? "Drag the Xcode version to compare against")
		}
		.padding()
		.frame(
			maxWidth: .infinity,
			maxHeight: .infinity
		)
		.overlay(content: {
			RoundedRectangle(cornerRadius: 10)
				.stroke(
					Color.accentColor,
					style: .init(lineWidth: 2, dash: [10, 2])
				)
		})
		.padding()
		.dropDestination(for: URL.self) { items, _ in
			guard items.count == 1 else { return false }

			do {
				against = try .init(path: items.first!)
				return true
			} catch {
				print("Drop error: \(error)")
				return false
			}
		}
	}

	var toSection: some View {
		VStack {
			to?.icon
			Text(to?.path.path() ?? "Drag the Xcode version to compare to")
		}
		.padding()
		.frame(
			maxWidth: .infinity,
			maxHeight: .infinity
		)
		.overlay(content: {
			RoundedRectangle(cornerRadius: 10)
				.stroke(
					Color.accentColor,
					style: .init(lineWidth: 2, dash: [10, 2])
				)
		})
		.padding()
		.dropDestination(for: URL.self) { items, _ in
			guard items.count == 1 else { return false }

			do {
				to = try .init(path: items.first!)
				return true
			} catch {
				print("Drop error: \(error)")
				return false
			}
		}
	}
}

#Preview {
	ChoosePathsView()
		.environment(DataModel())
}
