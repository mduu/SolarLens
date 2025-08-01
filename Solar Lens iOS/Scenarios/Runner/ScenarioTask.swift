import Foundation

protocol ScenarioTask {
    var scenarioName: LocalizedStringResource { get }

    func run<TParameters: ScenarioTaskParameters, TState: ScenarioTaskState>(
        host: ScenarioHost,
        parameters: TParameters,
        state: TState
    ) async throws -> ScenarioTaskRunResult
}
