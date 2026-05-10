internal import Foundation

extension AutomationBatteryToCar: AutomationLiveActivityProvider {

    func makeLiveActivityContentState(
        state: AutomationState,
        parameters: AutomationParameters
    ) -> AutomationLiveActivityAttributes.ContentState? {
        guard let live = state.batteryToCar,
              let params = parameters.batteryToCar
        else {
            return nil
        }

        // Before the first tick, lastTickAt is nil — we still want the
        // activity to render immediately when the user taps Start, so fall
        // back to "now". Subsequent ticks will overwrite it.
        let startedAt = live.lastTickAt ?? Date()
        let soc = live.lastBatteryPercentage ?? live.startSoc
        // Estimate from current setting × W/A. Good enough for the LA
        // headline; precise enough that the user notices changes when the
        // controller ramps. The runner doesn't persist actual station power
        // in state, so we don't have a live reading here.
        let stationW = Int(
            Double(live.currentAmps) * params.phases.fallbackWattsPerAmp
        )
        let kWh = String(format: "%.2f", live.kWhTransferred)

        let payload = BatteryToCarPayload(
            batterySoc: soc,
            floorSoc: params.minBatteryLevel,
            stationPowerW: stationW,
            currentAmps: live.currentAmps,
            kWhTransferred: live.kWhTransferred,
            forecastedFloorAt: live.forecastedFloorAt
        )

        return AutomationLiveActivityAttributes.ContentState(
            iconSystemName: Automation.BatteryToCar
                .liveActivityIconSystemName,
            startedAt: startedAt,
            primaryMetric: .init(
                label: String(localized: "Total"),
                value: "\(kWh) kWh"
            ),
            secondaryMetric: .init(
                label: String(localized: "Battery"),
                value: "\(soc)%"
            ),
            payload: .batteryToCar(payload)
        )
    }
}
