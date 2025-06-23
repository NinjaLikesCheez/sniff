public enum Platform: Hashable {
	public typealias Version = String

	case iOS(Version?)
	case iOSApplicationExtension(Version?)
	case macOS(Version?)
	case macOSApplicationExtension(Version?)
	case macCatalyst(Version?)
	case macCatalystApplicationExtension(Version?)
	case watchOS(Version?)
	case watchOSApplicationExtension(Version?)
	case tvOS(Version?)
	case tvOSApplicationExtension(Version?)
	case visionOS(Version?)
	case visionOSApplicationExtension(Version?)
	case swift(Version?)
	case all

	public init(_ argument: String) {
		// Acceptable formats:
		// iOS
		// iOS 17
		// iOS 17.0
		// iOS 17.0.1

		let components = argument.split(separator: " ")
		guard components.count > 1 else {
			self = Platform.fromName(String(components[0]))
			return
		}

		guard components.count == 2 else {
			fatalError("Invalid format for Platform: \(argument)")
		}

		let name = String(components[0])
		let version = String(components[1])

		self = Platform.fromName(name, andVersion: version)
	}

	static func fromName(_ name: String, andVersion version: Version? = nil) -> Platform {
		switch name {
		case "iOS":
			return .iOS(version)
		case "iOSApplicationExtension":
			return .iOSApplicationExtension(version)
		case "macOS":
			return .macOS(version)
		case "macOSApplicationExtension":
			return .macOSApplicationExtension(version)
		case "macCatalyst":
			return .macCatalyst(version)
		case "macCatalystApplicationExtension":
			return .macCatalystApplicationExtension(version)
		case "watchOS":
			return .watchOS(version)
		case "watchOSApplicationExtension":
			return .watchOSApplicationExtension(version)
		case "tvOS":
			return .tvOS(version)
		case "tvOSApplicationExtension":
			return .tvOSApplicationExtension(version)
		case "visionOS":
			return .visionOS(version)
		case "visionOSApplicationExtension":
			return .visionOSApplicationExtension(version)
		case "swift":
			return .swift(version)
		case "*":
			return .all
		default:
			fatalError("Unknown platform: \(name)")
		}
	}

	var name: String {
		switch self {
		case .iOS:
			"iOS"
		case .iOSApplicationExtension:
			"iOSApplicationExtension"
		case .macOS:
			"macOS"
		case .macOSApplicationExtension:
			"macOSApplicationExtension"
		case .macCatalyst:
			"macCatalyst"
		case .macCatalystApplicationExtension:
			"macCatalystApplicationExtension"
		case .watchOS:
			"watchOS"
		case .watchOSApplicationExtension:
			"watchOSApplicationExtension"
		case .tvOS:
			"tvOS"
		case .tvOSApplicationExtension:
			"tvOSApplicationExtension"
		case .visionOS:
			"visionOS"
		case .visionOSApplicationExtension:
			"visionOSApplicationExtension"
		case .swift:
			"swift"
		case .all:
			"*"
		}
	}
}
