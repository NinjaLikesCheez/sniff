//
//  CodeDiffView.swift
//  Sniff
//
//  Created by ninji on 30/06/2025.
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

import SwiftUI
import WebKit
import HighlightSwift

// TODO: https://stackoverflow.com/questions/54270287/wkwebview-inside-scroll-view
struct WebViewWrapper: NSViewRepresentable {
		var content: AttributedString

	init(_ attributedString: AttributedString) {
		self.content = attributedString
	}

		func makeNSView(context: Context) -> WKWebView {
			let view = WKWebView()

			do {
				let nsString = NSAttributedString(content)
				let htmlData = try nsString.data(from: NSMakeRange(0, nsString.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.html])
				let htmlString = String(data: htmlData, encoding: .utf8)!
				view.loadHTMLString(htmlString, baseURL: nil)

				return view
			} catch {
				fatalError("Failed to WebKit bro")
			}
		}

		func updateNSView(_ nsView: WKWebView, context: Context) {
			do {
				let nsString = NSAttributedString(content)
				let htmlData = try nsString.data(from: NSMakeRange(0, nsString.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.html])
				let htmlString = String(data: htmlData, encoding: .utf8)!
				nsView.loadHTMLString(htmlString, baseURL: nil)
			} catch {
				fatalError("Failed to WebKit bro")
			}
		}
}

struct SnippetDiffPreview: View {
	let diff: CodeDiff.SnippetDiff

	var body: some View {
		HStack(alignment: .top) {
			let (original, new) = generateTexts()
			WebViewWrapper(original.reduce(into: AttributedString(), { $0.append($1 + "\n") }))
				.frame(minWidth: 200, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
			Divider()
			//			block(new)
			WebViewWrapper(new.reduce(into: AttributedString(), { $0.append($1 + "\n") }))
				.frame(minWidth: 200, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
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
		let diff = CodeDiff.diff(text: newCode, from: originalCode)
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

	let diff = CodeDiff.diff(snippet: originalCode, from: newCode)

	return SnippetDiffPreview(diff: diff)
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
				SnippetDiffPreview(diff: CodeDiff.diff(snippet: originalCode, from: newCode))
			}
			.padding()
			.frame(height: 600)
		}
	}

	return V()
}

#endif

