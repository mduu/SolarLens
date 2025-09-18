import Foundation

protocol ScenarioTask {
    var scenarioName: LocalizedStringResource { get }

    func run(
        host: ScenarioHost,
        parameters: ScenarioParameters,
        state: ScenarioState
    ) async throws -> ScenarioState
}
