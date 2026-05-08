internal import Foundation

extension AutomationAutoResetChargingMode: AutomationLiveActivityProvider {

    func makeLiveActivityContentState(
        state: AutomationState,
        parameters: AutomationParameters
    ) -> AutomationLiveActivityAttributes.ContentState? {
        guard let live = state.autoResetChargingMode,
              let params = parameters.autoResetChargingMode
        else {
            return nil
        }

        // Before the first tick, startedAt is nil. Fall back to "now" so
        // the LA renders immediately on Start; subsequent updates carry
        // the real start date.
        let startedAt = live.startedAt ?? Date()

        let activeName = String(
            localized: params.activeChargingMode.localizedTitle
        )
        let afterResetName = String(
            localized: params.afterResetChargingMode.localizedTitle
        )

        let payload = AutoResetChargingModePayload(
            activeModeTitle: activeName,
            afterResetModeTitle: afterResetName,
            resetAt: params.resetAt
        )

        return AutomationLiveActivityAttributes.ContentState(
            iconSystemName: Automation.AutoResetChargingMode
                .liveActivityIconSystemName,
            startedAt: startedAt,
            primaryMetric: .init(
                label: String(localized: "Resets"),
                // Used by Dynamic Island compact-trailing — a fallback
                // string for the rare case the LA renderer can't pull a
                // live timer. The actual trailing region renders a live
                // `Text(timerInterval:)` instead.
                value: shortRelativeTime(to: params.resetAt)
            ),
            secondaryMetric: .init(
                label: String(localized: "After reset"),
                value: afterResetName
            ),
            payload: .autoResetChargingMode(payload)
        )
    }

    /// Compact "in 1h 5m" / "in 12s" rendering for the rare snapshot path
    /// where SwiftUI's native countdown view isn't available.
    private func shortRelativeTime(to date: Date) -> String {
        let secs = max(0, Int(date.timeIntervalSinceNow))
        if secs < 60 { return "\(secs)s" }
        let mins = secs / 60
        if mins < 60 { return "\(mins)m" }
        let hours = mins / 60
        let rem = mins % 60
        return rem == 0 ? "\(hours)h" : "\(hours)h \(rem)m"
    }
}
