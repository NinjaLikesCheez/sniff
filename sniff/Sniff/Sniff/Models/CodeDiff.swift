//
//  Diff.swift
//  Sniff
//
//  Created by ninji on 27/06/2025.
//

// This is a slight modification of https://github.com/intitni/CopilotForXcode/blob/main/Tool/Sources/CodeDiff/CodeDiff.swift
/*
 MIT License

 Copyright (c) 2024 Shangxin Guo <int123c@gmail.com>

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation

struct CodeDiff {
	init() {}

	typealias LineDiff = CollectionDifference<String>

	struct SnippetDiff: Equatable, CustomStringConvertible {
		struct Change: Equatable {
			let offset: Int
			let element: String
		}

		struct Line: Equatable {
			enum Diff: Equatable {
				case unchanged
				case mutated(changes: [Change])
			}

			let text: String
			let diff: Diff

			var description: String {
				switch diff {
				case .unchanged:
					text
				case let .mutated(changes):
					text + "   [" + changes.map { change in
						"\(change.offset): \(change.element)"
					}.joined(separator: " | ") + "]"
				}
			}
		}

		struct Section: Equatable, CustomStringConvertible {
			let oldOffset: Int
			let newOffset: Int

			var oldSnippet: [Line]
			var newSnippet: [Line]

			var isEmpty: Bool {
				oldSnippet.isEmpty && newSnippet.isEmpty
			}

			var description: String {
				func decorateLine(at index: Int, for line: Line, with token: Character) -> String {
					let lineIndex = String(format: "%3d", index + 1) + "   "

					return switch line.diff {
					case .unchanged:
						"\(lineIndex)|    \(line.description)"
					case .mutated:
						"\(lineIndex)| \(token)  \(line.description)"
					}
				}

				let old = oldSnippet.enumerated()
					.map { decorateLine(at: $0, for: $1, with: "-")}
					.joined(separator: "\n")

				let new = newSnippet.enumerated()
					.map { decorateLine(at: $0, for: $1, with: "+") }
					.joined(separator: "\n")

				return "\(old)\n\(new)"
			}
		}

		var sections: [Section]

		var description: String {
			"Diff:\n" + sections.map(\.description).joined(separator: "\n---\n") + "\n"
		}
	}
}

extension CodeDiff {
	// diff a line change
	func diff(text: String, from oldText: String) -> LineDiff {
		typealias Change = LineDiff.Change

		let diffByCharacter = text.difference(from: oldText)

		// convert each difference item to a LineDiff change
		let initialChanges = diffByCharacter.map { item -> Change in
			switch item {
			case let .insert(offset, element, associatedWith):
				return .insert(offset: offset, element: String(element), associatedWith: associatedWith)
			case let .remove(offset, element, associatedWith):
				return .remove(offset: offset, element: String(element), associatedWith: associatedWith)
			}
		}

		// merge consecutive changes
		let mergedChanges = initialChanges.reduce(into: [Change]()) { result, change in
			guard let lastChange = result.last else {
				result.append(change)
				return
			}

			let mergedChange = tryMergeChanges(lastChange, change)
			if let merged = mergedChange {
				result[result.count - 1] = merged
			} else {
				result.append(change)
			}
		}

		return .init(mergedChanges) ?? [].difference(from: [])
	}

	private func tryMergeChanges(_ first: LineDiff.Change, _ second: LineDiff.Change) -> LineDiff.Change? {
		switch (first, second) {
		case let (.insert(offset, element, associatedWith), .insert(offsetB, elementB, _))
			where offset + element.count == offsetB:
			return .insert(
				offset: offset,
				element: element + String(elementB),
				associatedWith: associatedWith
			)

		case let (.remove(offset, element, associatedWith), .remove(offsetB, elementB, _))
			where offset - 1 == offsetB:
			return .remove(
				offset: offsetB,
				element: String(elementB) + element,
				associatedWith: associatedWith
			)

		default:
			return nil
		}
	}
}

extension CodeDiff {
	// diff a snippet (mulitiple lines)
	func diff(snippet: String, from oldSnippet: String) -> SnippetDiff {
		let newLines = snippet.split(whereSeparator: \.isNewline)
		let oldLines = oldSnippet.split(whereSeparator: \.isNewline)
		let diffByLine = newLines.difference(from: oldLines)

		let groups = generateDiffSections(diffByLine)

		var oldLineIndex = 0
		var newLineIndex = 0
		var sectionIndex = 0
		var result = SnippetDiff(sections: [])

		while oldLineIndex < oldLines.endIndex || newLineIndex < newLines.endIndex {
			guard let groupItem = groups[safe: sectionIndex] else {
				break
			}

			let unchangedLines = createUnchangedLines(
				oldLines: oldLines,
				newLines: newLines,
				oldLineIndex: oldLineIndex,
				newLineIndex: newLineIndex,
				groupItem: groupItem
			)

			// handle lines before sections
			let beforeSection = SnippetDiff.Section(
				oldOffset: oldLineIndex,
				newOffset: newLineIndex,
				oldSnippet: unchangedLines,
				newSnippet: unchangedLines
			)

			oldLineIndex += unchangedLines.count
			newLineIndex += unchangedLines.count

			if !beforeSection.isEmpty {
				result.sections.append(beforeSection)
			}

			// handle lines inside sections
			var insideSection = SnippetDiff.Section(
				oldOffset: oldLineIndex,
				newOffset: newLineIndex,
				oldSnippet: [],
				newSnippet: []
			)

			for i in 0..<max(groupItem.remove.count, groupItem.insert.count) {
				let oldLine = (groupItem.remove[safe: i]?.element).map(String.init) ?? ""
				let newLine = (groupItem.insert[safe: i]?.element).map(String.init) ?? ""

				let diff = diff(text: newLine, from: oldLine)

				if !oldLine.isEmpty {
					insideSection.oldSnippet.append(.init(
						text: oldLine,
						diff: .mutated(changes: diff.removals.compactMap { change in
							guard case let .remove(offset, element, _) = change else { return nil }
							return .init(offset: offset, element: element)
						})
					))
				}

				if !newLine.isEmpty {
					insideSection.newSnippet.append(.init(
						text: newLine,
						diff: .mutated(changes: diff.insertions.compactMap { change in
							guard case let .insert(offset, element, _) = change else { return nil }
							return .init(offset: offset, element: element)
						})
					))
				}
			}

			oldLineIndex += groupItem.remove.count
			newLineIndex += groupItem.insert.count
			sectionIndex += 1

			if !insideSection.isEmpty {
				result.sections.append(insideSection)
			}
		}

		if let finishingSection = createFinishingSection(
			oldLineIndex: oldLineIndex,
			oldLines: oldLines,
			newLineIndex: newLineIndex,
			newLines: newLines
		) {
			result.sections.append(finishingSection)
		}

		return result
	}

	private func createFinishingSection(oldLineIndex: Int, oldLines: [Substring], newLineIndex: Int, newLines: [Substring]) -> CodeDiff.SnippetDiff.Section? {
		let oldSnippet = (oldLineIndex < oldLines.endIndex)
			? oldLines[oldLineIndex..<oldLines.endIndex].map { CodeDiff.SnippetDiff.Line(text: String($0), diff: CodeDiff.SnippetDiff.Line.Diff.unchanged) }
			: []
		let newSnippet = (newLineIndex < newLines.endIndex)
			? newLines[newLineIndex..<newLines.endIndex].map { CodeDiff.SnippetDiff.Line(text: String($0), diff: CodeDiff.SnippetDiff.Line.Diff.unchanged) }
			: []

		let section = CodeDiff.SnippetDiff.Section(
			oldOffset: oldLineIndex,
			newOffset: newLineIndex,
			oldSnippet: oldSnippet,
			newSnippet: newSnippet
		)

		return section.isEmpty ? nil : section
	}


	private func createUnchangedLines(
		oldLines: [Substring],
		newLines: [Substring],
		oldLineIndex: Int,
		newLineIndex: Int,
		groupItem: DiffGroupItem<Substring>
	) -> [CodeDiff.SnippetDiff.Line] {
		if let removeOffset = groupItem.remove.first?.offset {
			return oldLines[oldLineIndex..<removeOffset].map {
				CodeDiff.SnippetDiff.Line(text: String($0), diff: .unchanged)
			}
		} else if let insertOffset = groupItem.insert.first?.offset {
			return newLines[newLineIndex..<insertOffset].map {
				CodeDiff.SnippetDiff.Line(text: String($0), diff: .unchanged)
			}
		} else {
			return []
		}
	}
}

private extension CodeDiff {
	func generateDiffSections(_ diff: CollectionDifference<Substring>)
	-> [DiffGroupItem<Substring>]
	{
		guard !diff.isEmpty else { return [] }

		let removes = ChangeSection.sectioning(diff.removals)
		let inserts = ChangeSection.sectioning(diff.insertions)

		var groups = [DiffGroupItem<Substring>]()

		var removeOffset = 0
		var insertOffset = 0
		var removeIndex = 0
		var insertIndex = 0

		while removeIndex < removes.count || insertIndex < inserts.count {
			let removeSection = removes[safe: removeIndex]
			let insertSection = inserts[safe: insertIndex]

			if let removeSection, let insertSection {
				let ro = removeSection.offset - removeOffset
				let io = insertSection.offset - insertOffset
				if ro == io {
					groups.append(.init(
						remove: removeSection.changes.map { .init(change: $0) },
						insert: insertSection.changes.map { .init(change: $0) }
					))
					removeOffset += removeSection.changes.count
					insertOffset += insertSection.changes.count
					removeIndex += 1
					insertIndex += 1
				} else if ro < io {
					groups.append(.init(
						remove: removeSection.changes.map { .init(change: $0) },
						insert: []
					))
					removeOffset += removeSection.changes.count
					removeIndex += 1
				} else {
					groups.append(.init(
						remove: [],
						insert: insertSection.changes.map { .init(change: $0) }
					))
					insertOffset += insertSection.changes.count
					insertIndex += 1
				}
			} else if let removeSection {
				groups.append(.init(
					remove: removeSection.changes.map { .init(change: $0) },
					insert: []
				))
				removeIndex += 1
			} else if let insertSection {
				groups.append(.init(
					remove: [],
					insert: insertSection.changes.map { .init(change: $0) }
				))
				insertIndex += 1
			}
		}

		return groups
	}
}

private extension Array {
	subscript(safe index: Int) -> Element? {
		guard index >= 0, index < count else { return nil }
		return self[index]
	}

	subscript(safe index: Int, fallback fallback: Element) -> Element {
		guard index >= 0, index < count else { return fallback }
		return self[index]
	}
}

private extension CollectionDifference.Change {
	var offset: Int {
		switch self {
		case let .insert(offset, _, _):
			return offset
		case let .remove(offset, _, _):
			return offset
		}
	}
}

private struct DiffGroupItem<Element> {
	struct Item {
		var offset: Int
		var element: Element

		init(offset: Int, element: Element) {
			self.offset = offset
			self.element = element
		}

		init(change: CollectionDifference<Element>.Change) {
			offset = change.offset
			switch change {
			case let .insert(_, element, _):
				self.element = element
			case let .remove(_, element, _):
				self.element = element
			}
		}
	}

	var remove: [Item]
	var insert: [Item]
}

private struct ChangeSection<Element> {
	var offset: Int { changes.first?.offset ?? 0 }
	var changes: [CollectionDifference<Element>.Change]

	static func sectioning(_ changes: [CollectionDifference<Element>.Change]) -> [Self] {
		guard !changes.isEmpty else { return [] }

		let sortedChanges = changes.sorted { $0.offset < $1.offset }
		var sections = [Self]()
		var currentSection = [CollectionDifference<Element>.Change]()

		for change in sortedChanges {
			if let lastOffset = currentSection.last?.offset {
				if change.offset == lastOffset + 1 {
					currentSection.append(change)
				} else {
					sections.append(Self(changes: currentSection))
					currentSection.removeAll()
					currentSection.append(change)
				}
			} else {
				currentSection.append(change)
				continue
			}
		}

		if !currentSection.isEmpty {
			sections.append(Self(changes: currentSection))
		}

		return sections
	}
}

import SwiftUI

struct SnippetDiffPreview: View {
	let originalCode: String
	let newCode: String

	var body: some View {
		HStack(alignment: .top) {
			let (original, new) = generateTexts()
			block(original)
			Divider()
			block(new)
		}
		.padding()
		.font(.body.monospaced())
	}

	@ViewBuilder
	func block(_ code: [AttributedString]) -> some View {
		LazyVStack(alignment: .leading) {
			if !code.isEmpty {
				ForEach(0..<code.count, id: \.self) { index in
					HStack {
						Text("\(index)")
							.foregroundStyle(.secondary)
							.frame(width: 30)
						Text(code[index])
							.multilineTextAlignment(.leading)
							.frame(minWidth: 260, alignment: .leading)
					}
				}
			}
		}
	}

	func generateTexts() -> (original: [AttributedString], new: [AttributedString]) {
		let diff = CodeDiff().diff(snippet: newCode, from: originalCode)
		let new = diff.sections.flatMap {
			$0.newSnippet.map {
				let text = $0.text.trimmingCharacters(in: .newlines)
				let string = NSMutableAttributedString(string: text)
				if case let .mutated(changes) = $0.diff {
					string.addAttribute(
						.backgroundColor,
						value: NSColor.green.withAlphaComponent(0.1),
						range: NSRange(location: 0, length: text.count)
					)

					for diffItem in changes {
						string.addAttribute(
							.backgroundColor,
							value: NSColor.green.withAlphaComponent(0.5),
							range: NSRange(
								location: diffItem.offset,
								length: min(
									text.count - diffItem.offset,
									diffItem.element.count
								)
							)
						)
					}
				}
				return string
			}
		}

		let original = diff.sections.flatMap {
			$0.oldSnippet.map {
				let text = $0.text.trimmingCharacters(in: .newlines)
				let string = NSMutableAttributedString(string: text)
				if case let .mutated(changes) = $0.diff {
					string.addAttribute(
						.backgroundColor,
						value: NSColor.red.withAlphaComponent(0.1),
						range: NSRange(location: 0, length: text.count)
					)

					for diffItem in changes {
						string.addAttribute(
							.backgroundColor,
							value: NSColor.red.withAlphaComponent(0.5),
							range: NSRange(
								location: diffItem.offset,
								length: min(text.count - diffItem.offset, diffItem.element.count)
							)
						)
					}
				}

				return string
			}
		}

		return (original.map(AttributedString.init), new.map(AttributedString.init))
	}
}

struct LineDiffPreview: View {
	let originalCode: String
	let newCode: String

	var body: some View {
		VStack(alignment: .leading) {
			let (original, new) = generateTexts()
			Text(original)
			Divider()
			Text(new)
		}
		.padding()
		.font(.body.monospaced())
	}

	func generateTexts() -> (original: AttributedString, new: AttributedString) {
		let diff = CodeDiff().diff(text: newCode, from: originalCode)
		let original = NSMutableAttributedString(string: originalCode)
		let new = NSMutableAttributedString(string: newCode)

		for item in diff {
			switch item {
			case let .insert(offset, element, _):
				new.addAttribute(
					.backgroundColor,
					value: NSColor.green.withAlphaComponent(0.5),
					range: NSRange(location: offset, length: element.count)
				)
			case let .remove(offset, element, _):
				original.addAttribute(
					.backgroundColor,
					value: NSColor.red.withAlphaComponent(0.5),
					range: NSRange(location: offset, length: element.count)
				)
			}
		}

		return (.init(original), .init(new))
	}
}

#if DEBUG

#Preview("Line Diff") {
	let originalCode = """
 let foo = Foo() // yes
 """
	let newCode = """
 var foo = Bar()
 """

	return LineDiffPreview(originalCode: originalCode, newCode: newCode)
}

#Preview("Snippet Diff") {
	let originalCode = """
 let foo = Foo()
 print(foo)
 // do something
 foo.foo()
 func zoo() {}
 """
	let newCode = """
 var foo = Bar()
 // do something
 foo.bar()
 func zoo() {
 print("zoo")
 }
 """

	return SnippetDiffPreview(originalCode: originalCode, newCode: newCode)
}

#Preview("Code Diff Editor") {
	struct V: View {
		@State var originalCode = ""
		@State var newCode = ""

		var body: some View {
			VStack {
				HStack {
					VStack {
						Text("Original")
						TextEditor(text: $originalCode)
							.frame(width: 300, height: 200)
					}
					VStack {
						Text("New")
						TextEditor(text: $newCode)
							.frame(width: 300, height: 200)
					}
				}
				.font(.body.monospaced())
				SnippetDiffPreview(originalCode: originalCode, newCode: newCode)
			}
			.padding()
			.frame(height: 600)
		}
	}

	return V()
}

#endif
