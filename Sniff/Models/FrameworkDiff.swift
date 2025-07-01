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

class FrameworkDiff {
	typealias Difference = CollectionDifference<String>

	let againstSDK: XcodeModel.SDK
	let toSDK: XcodeModel.SDK

	let againstFramework: XcodeModel.Framework?
	let toFramework: XcodeModel.Framework

	let againstFilePaths: [String: URL]
	let toFilePaths: [String: URL]

	init(againstSDK: XcodeModel.SDK, toSDK: XcodeModel.SDK, framework: XcodeModel.Framework) {
		self.againstSDK = againstSDK
		self.toSDK = toSDK

		self.toFramework = framework
		self.againstFramework = againstSDK.findFramework(named: framework.name)

		self.againstFilePaths = againstFramework?.diffablePaths.reduce(into: [:], { $0[$1.lastPathComponent] = $1 }) ?? [:]
		self.toFilePaths = toFramework.diffablePaths.reduce(into: [:], { $0[$1.lastPathComponent] = $1 })
	}

	func diff() throws -> [FileDiff] {
		let toFileKeys = Set(toFilePaths.keys)
		let againstFileKeys = Set(againstFilePaths.keys)

		let differences = Array(toFilePaths.keys).difference(from: Array(againstFilePaths.keys)).inferringMoves()
		let common = toFileKeys.intersection(againstFileKeys)

		var result = [FileDiff]()

		for difference in differences {
			switch difference {
			case let .insert(offset: _, element: element, associatedWith: associatedWith):
				if associatedWith == nil {
					result.append(
						.init(
							to: toFilePaths[element]!,
							against: nil,
							diff: .added(try String(contentsOf: toFilePaths[element]!, encoding: .utf8))
						)
					)
				}
			case let .remove(offset: _, element: element, associatedWith: associatedWith):
				if associatedWith == nil {
					result.append(
						.init(
							to: nil,
							against: againstFilePaths[element]!,
							diff: .removed(try String(contentsOf: againstFilePaths[element]!, encoding: .utf8))
						)
					)
				}
			}
		}

		for element in common {
			result.append(
				.init(
					to: toFilePaths[element]!,
					against: againstFilePaths[element]!,
					diff: .diff(
						snippet: CodeDiff.diff(
							snippet: try String(contentsOf: toFilePaths[element]!, encoding: .utf8),
							from: try String(contentsOf: againstFilePaths[element]!, encoding: .utf8)
						)
					)
				)
			)
		}

		return result
	}

	struct FileDiff: Identifiable {
		var name: String { to?.lastPathComponent ?? against?.lastPathComponent ?? "Unknown" }

		var id: String { name }

		let to: URL?
		let against: URL?

		let diff: Diff

		enum Diff {
			case added(String)
			case removed(String)
			case diff(snippet: CodeDiff.SnippetDiff)
		}
	}
}
