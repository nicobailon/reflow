import Foundation

public enum Aggressiveness: String, Codable, CaseIterable, Sendable {
    case conservative
    case normal
    case aggressive
    
    public var displayName: String {
        switch self {
        case .conservative: "Conservative"
        case .normal: "Normal"
        case .aggressive: "Aggressive"
        }
    }
}

public struct ReflowOptions: Sendable {
    public var aggressiveness: Aggressiveness
    public var markdownAware: Bool
    public var customPatterns: [String]
    
    public init(
        aggressiveness: Aggressiveness = .normal,
        markdownAware: Bool = true,
        customPatterns: [String] = []
    ) {
        self.aggressiveness = aggressiveness
        self.markdownAware = markdownAware
        self.customPatterns = customPatterns
    }
    
    public static let `default` = ReflowOptions()
}

public struct ReflowStatistics: Codable, Sendable {
    public var sessionLinesJoined: Int
    public var sessionPastes: Int
    public var allTimeLinesJoined: Int
    public var allTimePastes: Int
    
    public init(
        sessionLinesJoined: Int = 0,
        sessionPastes: Int = 0,
        allTimeLinesJoined: Int = 0,
        allTimePastes: Int = 0
    ) {
        self.sessionLinesJoined = sessionLinesJoined
        self.sessionPastes = sessionPastes
        self.allTimeLinesJoined = allTimeLinesJoined
        self.allTimePastes = allTimePastes
    }
}

public struct ReflowResult: Sendable {
    public let original: String
    public let reflowed: String
    public let linesJoined: Int
    public let paragraphsDetected: Int
    public var wasTransformed: Bool { original != reflowed }
    
    public init(
        original: String,
        reflowed: String,
        linesJoined: Int,
        paragraphsDetected: Int
    ) {
        self.original = original
        self.reflowed = reflowed
        self.linesJoined = linesJoined
        self.paragraphsDetected = paragraphsDetected
    }
}

public struct SourceAppInfo: Sendable {
    public let bundleIdentifier: String?
    public let appName: String?
    public let isRecognizedTerminal: Bool
    public let isMixedSourceApp: Bool
    
    public init(
        bundleIdentifier: String?,
        appName: String?,
        isRecognizedTerminal: Bool,
        isMixedSourceApp: Bool
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.isRecognizedTerminal = isRecognizedTerminal
        self.isMixedSourceApp = isMixedSourceApp
    }
}
