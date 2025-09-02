import Foundation

protocol ScenarioHost {
    func logSuccess()
    func logInfo(message: LocalizedStringResource)
    func logError(message: LocalizedStringResource)
    func logFailure()
    func logDebug(message: LocalizedStringResource)
    var energyManager: EnergyManager { get }
}
