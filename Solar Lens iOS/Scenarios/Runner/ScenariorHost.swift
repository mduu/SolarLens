import Foundation

protocol ScenariorHost {
    func logSuccess()
    func logInfo(message: LocalizedStringResource)
    func logError(message: LocalizedStringResource)
    func logFailure()
}
