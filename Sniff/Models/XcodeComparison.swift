//
//  XcodeComparison.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//
import Observation
import SwiftUI

@Observable
class XcodeComparison {
	let against: XcodeModel
	let to: XcodeModel

	init(against: XcodeModel, to: XcodeModel) {
		self.against = against
		self.to = to
	}
}

extension XcodeComparison {
	struct FrameworksComparison {
		typealias Difference = CollectionDifference<String>

		let against: [String: XcodeModel.Framework]
		let to: [String: XcodeModel.Framework]
		let difference: Difference

		init(against: [XcodeModel.Framework], to: [XcodeModel.Framework]) {
			self.against = against.reduce(into: [String: XcodeModel.Framework](), { $0[$1.name] = $1 })
			self.to = to.reduce(into: [String: XcodeModel.Framework](), { $0[$1.name] = $1 })

			let againstKeys = Array(self.against.keys).sorted(by: { $0 < $1 })
			let toKeys = Array(self.to.keys).sorted(by: { $0 < $1 })

			self.difference = toKeys.difference(from: againstKeys)
		}
	}
}
