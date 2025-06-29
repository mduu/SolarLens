import Foundation

protocol ScenariorHost {
    func logSccess()
    func logInfo(message: LocalizedStringResource)
    func logError(message: LocalizedStringResource)
    func logFailure()
}
