public enum ScenarioStatus: String, Codable {
    case none,
    case starting,
    case running,
    case finishedSuccessfull,
    case failed
}
