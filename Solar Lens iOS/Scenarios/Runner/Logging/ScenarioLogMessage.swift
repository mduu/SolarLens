import Foundation

public struct ScenarioLogMessage : Codable, Identifiable {
    public var id = UUID()
    public var time: Date = Date()
    public let message: LocalizedStringResource
    public var level: ScenarioLogMessageLevel
}

public enum ScenarioLogMessageLevel : Codable {
    case Debug
    case Success
    case Info
    case Error
    case Failure
}
