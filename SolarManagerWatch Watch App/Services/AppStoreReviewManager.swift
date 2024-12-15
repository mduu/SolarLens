import SwiftUI

/// Handles App-Store review requests for the entire app
class AppStoreReviewManager {
    @AppStorage("startupCount") private var startupCount = 0
    @AppStorage("chargingModeSetAtLeastOnce") private
        var chargingModeSetAtLeastOnce = false
    @AppStorage("solarDetailsShownAtLeastOnce") private
        var solarDetailsShownAtLeastOnce = false
    @AppStorage("lastTimeReviewRequested") private
        var lastTimeReviewRequested = 0

    static let shared = AppStoreReviewManager()

    func increaseStartupCount() {
        startupCount += 1
    }

    func setChargingModeSetAtLeastOnce() {
        chargingModeSetAtLeastOnce = true
    }

    func setSolarDetailsShownAtLeastOnce() {
        solarDetailsShownAtLeastOnce = true
    }

    func checkAndRequestReview(force: Bool = false) -> Bool {
        #if os(watchOS)
            if #available(watchOS 7.0, *) {
                
                if force || shouldAskForReview() {
                    return true
                }

            }
        #endif
        
        return false
    }
    
    func reviewShown() {
        lastTimeReviewRequested = Int(Date().timeIntervalSince1970)
    }

    private func shouldAskForReview() -> Bool {
        let lastTime = Date(
            timeIntervalSince1970: TimeInterval(lastTimeReviewRequested))

        return startupCount > 5
            && (chargingModeSetAtLeastOnce
                || solarDetailsShownAtLeastOnce)
            && isDateAtLeastSixMonthsAgo(lastTime)
    }

    private func isDateAtLeastSixMonthsAgo(_ date: Date) -> Bool {
        let sixMonthsAgo = Calendar.current.date(
            byAdding: .month, value: -6, to: Date())!
        
        return date < sixMonthsAgo
    }
}
