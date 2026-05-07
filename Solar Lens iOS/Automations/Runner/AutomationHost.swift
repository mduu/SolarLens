internal import Foundation

protocol AutomationHost {
    func logSuccess()
    func logInfo(message: LocalizedStringResource)
    func logError(message: LocalizedStringResource)
    func logFailure()
    func logDebug(message: LocalizedStringResource)
    var energyManager: EnergyManager { get }
}
