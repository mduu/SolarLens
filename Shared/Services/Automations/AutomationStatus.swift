public enum AutomationStatus: String, Codable, Sendable {
    case none = "none"
    case starting = "starting"
    case running = "running"
    case finishedSuccessful = "finished_successful"
    case failed = "failed"
}
