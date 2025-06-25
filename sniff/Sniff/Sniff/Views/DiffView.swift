//
//  DiffView.swift
//  Sniff
//
//  Created by ninji on 25/06/2025.
//

import SwiftUI

struct DiffView: View {
	@Binding var comparison: XcodeComparison
	var platform: XcodeModel.Platform
	var framework: XcodeModel.Framework

	init(comparison: Binding<XcodeComparison>, platform: XcodeModel.Platform, framework: XcodeModel.Framework) {
		self._comparison = comparison
		self.platform = platform
		self.framework = framework

		// Start calculating diff
	}

	var body: some View {
		Text("Diff \(framework.name)")
	}
}
