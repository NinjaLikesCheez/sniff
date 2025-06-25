//
//  ChangeLabel.swift
//  Sniff
//
//  Created by ninji on 25/06/2025.
//

import SwiftUI

struct ChangeLabel: View {
	var title: String
	var tint: Color

	init(_ title: String, tint: Color) {
		self.title = title
		self.tint = tint
	}

	var body: some View {
		Text(title)
			.font(.subheadline)
			.foregroundStyle(.primary)
			.padding(.horizontal, 10)
			.padding(.vertical, 4)
			.background(
				Capsule()
					.fill(tint.opacity(0.18))
			)
			.overlay(
				Capsule()
					.stroke(tint, lineWidth: 1.5)
			)
			.frame(maxHeight: 30)
	}
}
