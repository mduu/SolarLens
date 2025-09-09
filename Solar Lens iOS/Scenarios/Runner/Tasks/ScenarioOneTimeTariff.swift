import Foundation

final class ScenarioOneTimeTariff: ScenarioTask {
    public static let shared = ScenarioOneTimeTariff()

    let scenarioName: LocalizedStringResource = "1x Tariff"

    func run(
        host: any ScenarioHost,
        parameters: ScenarioParameters,
        state: ScenarioState
    )
        async throws -> ScenarioState
    {
        guard let oneTimeTariffState = state.oneTimeTariff else {
            host.logError(message: "No state for One Time Tariff")
            host.logFailure()
            return state.failed()
        }

        var overviewData = try? await host.energyManager.fetchOverviewData(lastOverviewData: nil)
        guard
            let overviewData = overviewData
        else {
            host.logError(message: "One time tariff: Unable to fetch overview data")
            return state  // keep current state for retry
        }

        var newState = state

        if !oneTimeTariffState.isStarted {
            newState = await startScenario(
                host: host,
                parameters: parameters,
                state: state,
                overviewData: overviewData
            )
        }

        let isWorkDone: Bool = // TODO

        return !isWorkDone
        ? continueScenario(
            host: host,
            state: newState
        )
        : await stopScenario(
            host: host,
            parameters: parameters,
            state: newState,
            overviewData: overviewData
        )
    }

    func startScenario(
        host: any ScenarioHost,
        parameters: ScenarioParameters,
        state: ScenarioState,
        overviewData: OverviewData
    ) async -> ScenarioState {
        host.logDebug(message: "One time tariff: start scenario")

        state.batteryToCar!.lastBatteryPercentage = overviewData.currentBatteryLevel

        // Backup previous state
        let charingStation = overviewData.chargingStations
            .first { $0.id == parameters.batteryToCar!.chargingDeviceId }

        guard let previousChargeMode: ChargingMode = charingStation?.chargingMode
        else {
            host.logError(message: "Failed to query previous charge mode")
            host.logFailure()

            return state.failed()
        }

        // Set charging mode to constant
        let setChargingModeResult = try? await host.energyManager.setCarChargingMode(
            sensorId: parameters.batteryToCar!.chargingDeviceId,
            carCharging: ControlCarChargingRequest(
                chargingMode: .withSolarOrLowTariff
            )
        )

        var endTime = // TODO Calculate end of tariff

        host.logDebug(message: "One time tariff: Scenario started")

        return ScenarioState(
            scenario: state.scenario!,
            status: ScenarioStatus.running,
            nextTaskRun: nil as Date?,
            oneTimeTariff: ScenarioOneTimeTariffState(
                isStarted: true,
                previousChargeMode: previousChargeMode
            )
        )
    }

    func continueScenario(
        host: any ScenarioHost,
        state: ScenarioState
    ) -> ScenarioState {
        host.logInfo(message: "Battery to car: scheduled next call")

        return ScenarioState(
            scenario: state.scenario!,
            status: ScenarioStatus.running,
            nextTaskRun: Date().addingTimeInterval(fiveMinutes),
            oneTimeTariff: ScenarioOneTimeTariffState(
                isStarted: true,
                previousChargeMode: state.batteryToCar!.previousChargingMode!
            )
        )
    }

    func stopScenario(
        host: any ScenarioHost,
        parameters: ScenarioParameters,
        state: ScenarioState,
        overviewData: OverviewData
    ) async -> ScenarioState {
        host.logDebug(message: "One time tariff: stopping scenario")

        // Reset charging mode
        let result = try? await host.energyManager.setCarChargingMode(
            sensorId: parameters.batteryToCar!.chargingDeviceId,
            carCharging: ControlCarChargingRequest(
                chargingMode: state.batteryToCar?.previousChargingMode ?? ChargingMode.withSolarPower
            )
        )

        host.logDebug(message: "One time tariff: Stopped at battery level \(overviewData.currentBatteryLevel ?? -1) %")
        host.logSuccess()

        return ScenarioState(
            scenario: state.scenario!,
            status: ScenarioStatus.finishedSuccessful,
            nextTaskRun: nil as Date?
        )
    }

}

class ScenarioOneTimeTariffParameters: Codable {
    var chargingDeviceId: String = ""

    init() {}

    init(chargingDeviceId: String) {
        self.chargingDeviceId = chargingDeviceId
    }
}

class ScenarioOneTimeTariffState: Codable {
    var isStarted: Bool = false
    var previousChargingMode: ChargingMode? = nil
    var endtime: Date? = nil

    init() {
    }

    init(
        isStarted: Bool,
        previousChargeMode: ChargingMode,
        endTime: Date?
    ) {
        self.isStarted = isStarted
        self.previousChargingMode = previousChargeMode
        self.endtime = endTime
    }
}
