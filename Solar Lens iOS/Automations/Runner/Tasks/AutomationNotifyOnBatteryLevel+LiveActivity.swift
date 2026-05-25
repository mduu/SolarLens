internal import Foundation

extension AutomationNotifyOnBatteryLevel: AutomationLiveActivityProvider {

    func makeLiveActivityContentState(
        state: AutomationState,
        parameters: AutomationParameters
    ) -> AutomationLiveActivityAttributes.ContentState? {
        guard let live = state.notifyOnBatteryLevel,
              let params = parameters.notifyOnBatteryLevel
        else {
            return nil
        }

        let startedAt = live.startedAt ?? Date()

        let payload = NotifyOnBatteryLevelPayload(
            targetBatteryLevel: params.targetBatteryLevel,
            comparison: params.comparison,
            lastBatteryLevel: live.lastBatteryLevel,
            startedAt: startedAt,
            forecastedTargetAt: live.forecastedTargetAt,
            lastBatteryChargeRateW: live.lastBatteryChargeRate
        )

        let comparator: String = {
            switch params.comparison {
            case .equalOrAbove: return "≥"
            case .equalOrBelow: return "≤"
            }
        }()

        return AutomationLiveActivityAttributes.ContentState(
            iconSystemName: Automation.NotifyOnBatteryLevel
                .liveActivityIconSystemName,
            startedAt: startedAt,
            primaryMetric: .init(
                label: String(localized: "Battery"),
                value: live.lastBatteryLevel.map { "\($0)%" } ?? "—"
            ),
            secondaryMetric: .init(
                label: String(localized: "Target"),
                value: "\(comparator) \(params.targetBatteryLevel)%"
            ),
            payload: .notifyOnBatteryLevel(payload)
        )
    }
}
