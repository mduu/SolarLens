internal import Foundation

struct AutomationLogMessage: Codable, Identifiable {
    var id = UUID()
    var time: Date = Date()
    let message: LocalizedStringResource
    var level: AutomationLogMessageLevel
}

enum AutomationLogMessageLevel: Codable {
    case Debug
    case Success
    case Info
    case Error
    case Failure
}
