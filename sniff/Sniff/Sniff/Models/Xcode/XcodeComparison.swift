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
//	struct PlatformsComparison {
//		typealias Difference = CollectionDifference<XcodeModel.Platform>
//
//		let against: [XcodeModel.Platform]
//		let to: [XcodeModel.Platform]
//		let differences: Difference
//
//		init(against: [XcodeModel.Platform], to: [XcodeModel.Platform]) {
//			self.against = against
//			self.to = to
//			self.differences = to.difference(from: against)
//		}
//	}
}

extension XcodeComparison {
	struct FrameworksComparison {
		typealias Difference = CollectionDifference<XcodeModel.Framework>

		let against: [XcodeModel.Framework]
		let to: [XcodeModel.Framework]
		let difference: Difference

		init(against: [XcodeModel.Framework], to: [XcodeModel.Framework]) {
			self.against = against
			self.to = to
			self.difference = to.difference(from: against)
		}
	}
}
