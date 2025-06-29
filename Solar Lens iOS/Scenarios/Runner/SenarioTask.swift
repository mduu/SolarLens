import Foundation

protocol ScenarioTask {
    var scenarioName: LocalizedStringResource { get }
    
    func run(host: ScenariorHost) async throws -> TimeInterval?
}
