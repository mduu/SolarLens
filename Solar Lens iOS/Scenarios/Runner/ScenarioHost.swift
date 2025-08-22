import Foundation

protocol ScenarioHost {
    func logSuccess()
    func logInfo(message: LocalizedStringResource)
    func logError(message: LocalizedStringResource)
    func logFailure()
}
