import Foundation

public struct ScenarioLogMessage {
    let time: Date
    let message: LocalizedStringResource
    var level: ScenarioLogMessageLevel
}

public enum ScenarioLogMessageLevel {
    case Debug
    case Success
    case Info
    case Error
    case Failure
}
