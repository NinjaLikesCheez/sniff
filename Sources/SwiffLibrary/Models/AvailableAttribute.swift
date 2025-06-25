import SwiftSyntax

public struct AvailableAttribute {
	public let options: [AvailabilityArgumentOption]
	public let decl: DeclSyntax

	public var platforms: [Platform] {
		options.compactMap { option in
			switch option {
			case .platform(let platform):
				return platform
			default:
				return nil
			}
		}
	}
}

public enum AvailabilityArgumentOption {
	public typealias Version = String

	case platform(Platform)
	case introduced(Version)
	case deprecated(Version)
	case obsoleted(Version)
	case message(String)
	case renamed(String)
	case noAsync
	case unavailable
}
