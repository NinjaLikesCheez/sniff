import SwiftSyntax

public final class AvailabilityVisitor: SyntaxVisitor {
	public var availabilityChecks: [AvailableAttribute] = []

	public convenience init() {
		self.init(viewMode: .all)
	}

	public override func visit(_ node: AvailabilityArgumentListSyntax) -> SyntaxVisitorContinueKind {
		// The third parent up is the decl that this is attached to
		guard let decl = node.parent?.parent?.parent?.as(DeclSyntax.self) else {
			dump(node)
			fatalError("Could not find decl for node: \(node)")
		}

		let options =
			node
			.children(viewMode: .all)
			.compactMap { child -> AvailabilityArgumentOption? in
				guard let child = child.as(AvailabilityArgumentSyntax.self) else {
					fatalError("A child not of AvailabilityArgumentSyntax: \(child)")
				}

				switch child.argument {
				case .availabilityLabeledArgument(let labeledArgument):
					return parseAvailabilityLabeledArgument(labeledArgument: labeledArgument)
				case .token(let token):
					switch token.text {
					case "unavailable":
						return .unavailable
					default:
						return .platform(Platform(token.text))
					}
				case .availabilityVersionRestriction(let platformVersion):
					let platformName = platformVersion.platform.text

					if let version = platformVersion.version {
						return .platform(Platform.fromName(platformName, andVersion: parseAvailabilityVersion(versionSyntax: version)))
					} else {
						return .platform(Platform.fromName(platformName))
					}
				}
			}

		let availabilityAttribute = AvailableAttribute(options: options, decl: decl)

		availabilityChecks.append(availabilityAttribute)

		return .visitChildren
	}
}

private func parseAvailabilityVersion(versionSyntax: VersionTupleSyntax) -> String {
	let minor = versionSyntax
		.components
		.map { "\($0.number.text)" }
		.joined(separator: ".")

	return "\(versionSyntax.major.text).\(minor)"
}

private func parseAvailabilityLabeledArgument(labeledArgument: AvailabilityLabeledArgumentSyntax) -> AvailabilityArgumentOption {
	if let value = labeledArgument.value.as(SimpleStringLiteralExprSyntax.self) {
		switch labeledArgument.label.text {
		case "message":
			return .message(value.segments.map { $0.content.text }.joined(separator: " "))
		case "renamed":
			return .renamed(value.segments.map { $0.content.text }.joined(separator: " "))
		default:
			break
		}
	} else if let value = labeledArgument.value.as(VersionTupleSyntax.self) {
		switch labeledArgument.label.text {
		case "introduced":
			return .introduced(parseAvailabilityVersion(versionSyntax: value))
		case "obsoleted":
			return .obsoleted(parseAvailabilityVersion(versionSyntax: value))
		case "deprecated":
			return .deprecated(parseAvailabilityVersion(versionSyntax: value))
		default:
			break
		}
	}

	fatalError("Unknown labeled argument: \(labeledArgument.label.text)")
}
