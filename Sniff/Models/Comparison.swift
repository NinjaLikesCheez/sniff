//
//  Comparison.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//
import Observation
import SwiftUI

@Observable
class XcodeComparison {
	let against: Xcode
	let to: Xcode

	init(against: Xcode, to: Xcode) {
		self.against = against
		self.to = to
	}
}

extension XcodeComparison {
	struct SDKComparison {
		typealias Difference = CollectionDifference<String>

		let against: [String: Xcode.Framework]
		let to: [String: Xcode.Framework]

		var changes: [Framework] = []

		init(against: [String: Xcode.Framework], to: [String: Xcode.Framework]) {
			self.against = against
			self.to = to

			let againstKeys = Array(self.against.keys).sorted(by: { $0 < $1 })
			let toKeys = Array(self.to.keys).sorted(by: { $0 < $1 })

			let differences = toKeys.difference(from: againstKeys).inferringMoves()

			var frameworks = [Framework]()

			for difference in differences {
				switch difference {
				case let .insert(offset: _, element: name, associatedWith: associatedWith):
					if associatedWith == nil {
						frameworks.append(.init(framework: to[name]!, change: .added))
					}
				case let .remove(offset: _, element: name, associatedWith: associatedWith):
					if associatedWith == nil {
						frameworks.append(.init(framework: against[name]!, change: .removed))
					}
				}
			}

			// Add all the common
			let common = Set(againstKeys).intersection(Set(toKeys))

			for item in common {
				let toCommon = to[item]!
				let againstCommon = against[item]!

				let toNamesAndPaths = toCommon.diffablePaths.reduce(into: [String: URL](), { $0[$1.lastPathComponent] = $1 })
				let againstNamesAndPaths = againstCommon.diffablePaths.reduce(into: [String: URL](), { $0[$1.lastPathComponent] = $1 })

				if toNamesAndPaths.keys.sorted() != againstNamesAndPaths.keys.sorted() {
					frameworks.append(.init(framework: toCommon, change: .modified))
				} else {
					// No different files, check contents of each
					for (key, value) in toNamesAndPaths {
						let againstPath = againstNamesAndPaths[key]!

						if FileManager.default.contentsEqual(atPath: value.path(), andPath: againstPath.path()) {
							frameworks.append(.init(framework: toCommon, change: .unchanged))
							break
						} else {
							frameworks.append(.init(framework: toCommon, change: .modified))
							break
						}
					}
				}
			}

			self.changes = frameworks.sorted(by: { $0.name < $1.name })
		}

		struct Framework: Identifiable, Hashable {
			var id: String { framework.id }
			var name: String { framework.name }

			let framework: Xcode.Framework
			let change: Change

			enum Change {
				case added
				case removed
				case unchanged
				case modified
			}
		}
	}
}

extension XcodeComparison {
	struct FrameworkComparison {
		typealias Difference = CollectionDifference<String>

		let against: Xcode.Framework?
		let to: Xcode.Framework?

		var changes: [FrameworkFile] = []

		init(against: Xcode.Framework?, to: Xcode.Framework?) {
			self.against = against
			self.to = to

			if against == nil && to == nil {
				return
			}

			// Get a mapping of file names to their paths
			let toFilesPath = to?.diffablePaths.reduce(into: [String: URL](), { $0[$1.lastPathComponent] = $1 }) ?? [:]
			let againstFilesPath = against?.diffablePaths.reduce(into: [String: URL](), { $0[$1.lastPathComponent] = $1 }) ?? [:]

			let differences = Array(toFilesPath.keys).difference(from: Array(againstFilesPath.keys)).inferringMoves()

			var results = [FrameworkFile]()

			for difference in differences {
				switch difference {
				case let .insert(offset: _, element: name, associatedWith: associatedWith):
					if associatedWith == nil {
						results.append(.init(path: toFilesPath[name]!, against: nil, change: .added))
					}
				case let .remove(offset: _, element: name, associatedWith: associatedWith):
					if associatedWith == nil {
						results.append(.init(path: againstFilesPath[name]!, against: nil, change: .removed))
					}
				}
			}

			let common = Set(toFilesPath.keys).intersection(Set(againstFilesPath.keys))

			for item in common {
				let toFilePath = toFilesPath[item]!
				let againstFilePath = againstFilesPath[item]!

				// Check if the files are different
				if FileManager.default.contentsEqual(atPath: toFilePath.path(), andPath: againstFilePath.path()) {
					results.append(.init(path: toFilePath, against: againstFilePath, change: .unchanged))
				} else {
					results.append(.init(path: toFilePath, against: againstFilePath, change: .modified))
				}
			}

			changes = results
		}

		struct FrameworkFile: Identifiable, Hashable {
			var id: URL { path }

			let path: URL
			let against: URL?
			let change: Change

			enum Change {
				case added
				case removed
				case unchanged
				case modified
			}
		}
	}
}
