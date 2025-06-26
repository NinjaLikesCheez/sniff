//
//  FrameworkDiff.swift
//  Sniff
//
//  Created by ninji on 26/06/2025.
//
import Foundation
import SwiftUI

struct Line: Identifiable, Hashable {
	var id: UUID { UUID() }

	let lineNumber: Int
	let text: String
	let changeStatus: ChangeStatus

	enum ChangeStatus {
		case added
		case removed
		case unchanged
	}
}

struct FrameworkDiff {
	typealias Difference = CollectionDifference<String>

	let againstSDK: XcodeModel.SDK
	let toSDK: XcodeModel.SDK

	let againstFramework: XcodeModel.Framework?
	let toFramework: XcodeModel.Framework

	let toLines: [String]
	let againstLines: [String]

	let difference: Difference

	let attributedLines: [Line]

	init(againstSDK: XcodeModel.SDK, toSDK: XcodeModel.SDK, framework: XcodeModel.Framework) {
		self.againstSDK = againstSDK
		self.toSDK = toSDK

		self.toFramework = framework
		self.againstFramework = againstSDK.findFramework(named: framework.name)

		// Currently only swift interface files are supported
		guard let toInterface = toFramework.swiftInterface else {
			toLines = []
			againstLines = []
			difference = .init([])!
			attributedLines = []
			print("Not a swift framework!")
			return
		}

		self.toLines = try! String(contentsOf: toInterface, encoding: .utf8).components(separatedBy: .newlines)
		var againstLines: [String] = []

		if let againstInterface = againstFramework?.swiftInterface {
			againstLines = (try? String(contentsOf: againstInterface, encoding: .utf8).components(separatedBy: .newlines)) ?? []
		}
		self.againstLines = againstLines

		self.difference = toLines.difference(from: againstLines)
		attributedLines = Self.attributeLines(toLines: toLines, difference: difference)
	}

	static func attributeLines(toLines: [String], difference: Difference) -> [Line] {
		var attributedStrings = [Line]()
		attributedStrings.reserveCapacity(toLines.count)

		// All inserted indicies
		let insertedIndicies: [Int] = difference.insertions
			.compactMap { change in
				if case let .insert(offset, element, associatedWith) = change {
					return offset
				}

				return nil
			}

		let removedIndicies: [Int] = difference.removals
			.compactMap { change in
				if case let .remove(offset, element, associatedWith) = change {
					return offset
				}

				return nil
			}

		for (index, line) in toLines.enumerated() {
//			var attributedLine = AttributedString(line + "\n")

			if insertedIndicies.contains(index) {
//				attributedLine.backgroundColor = .green
				attributedStrings.append(.init(lineNumber: index, text: line + "\n", changeStatus: .added))
			} else if removedIndicies.contains(index) {
//				attributedLine.backgroundColor = .red
				attributedStrings.append(.init(lineNumber: index, text: line + "\n", changeStatus: .removed))
			} else {
				attributedStrings.append(.init(lineNumber: index, text: line + "\n", changeStatus: .unchanged))
			}

//			attributedStrings.append(attributedLine)
		}

		return attributedStrings
	}
}

