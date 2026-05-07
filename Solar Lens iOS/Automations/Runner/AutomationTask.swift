internal import Foundation

protocol AutomationTask {
    var automationName: LocalizedStringResource { get }

    func run(
        host: AutomationHost,
        parameters: AutomationParameters,
        state: AutomationState
    ) async throws -> AutomationState
}
