import BackgroundTasks
import Foundation

final class ScenarioBatteryToCar: ScenarioTask {
    public static let shared = ScenarioBatteryToCar()

    let scenarioName: LocalizedStringResource = "Battery to Car"
    let tenSeconds: TimeInterval = 10
    let fiveMinutes: TimeInterval = 5 * 1  // 5 * 60 = 5 minutes

    func run(
        host: any ScenarioHost,
        parameters: ScenarioParameters,
        state: ScenarioState
    )
        async throws -> ScenarioState
    {
        guard let batteryToCarState = state.batteryToCar else {
            host.logError(message: "No state for Battery to Car")
            host.logFailure()
            return state.failed()
        }

        var overviewData = try? await host.energyManager.fetchOverviewData(lastOverviewData: nil)
        guard
            let overviewData = overviewData,
            let currentBatteryLevel = overviewData.currentBatteryLevel
        else {
            host.logError(message: "Battery to car: Unable to fetch overview data")
            return state  // keep current state for retry
        }

        var newState = state

        if !batteryToCarState.isStarted {
            newState = await startScenario(
                host: host,
                parameters: parameters,
                state: state,
                overviewData: overviewData
            )
        }

        let isWorkDone: Bool = currentBatteryLevel <= parameters.batteryToCar!.minBatteryLevel

        return !isWorkDone
            ? continueScenario(
                host: host,
                state: newState,
                lastBatteryPercentage: currentBatteryLevel
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
        host.logDebug(message: "Battery to car: start scenario")

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

        // TODO Set charging mode

        host.logDebug(message: "Battery to car: Scenario started")

        return ScenarioState(
            scenario: state.scenario!,
            status: ScenarioStatus.running,
            nextTaskRun: nil as Date?,
            batteryToCar: ScenarioBatteryToCarState(
                isStarted: true,
                lastBatteryPercentage: overviewData.currentBatteryLevel,
                previousChargeMode: previousChargeMode
            )
        )
    }

    func continueScenario(
        host: any ScenarioHost,
        state: ScenarioState,
        lastBatteryPercentage: Int
    ) -> ScenarioState {
        host.logInfo(message: "Battery to car: scheduled next call")

        return ScenarioState(
            scenario: state.scenario!,
            status: ScenarioStatus.running,
            nextTaskRun: Date().addingTimeInterval(fiveMinutes),
            batteryToCar: ScenarioBatteryToCarState(
                isStarted: true,
                lastBatteryPercentage: lastBatteryPercentage,
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
        host.logDebug(message: "Battery to car: stopping scenario")

        // Reset charging mode
        let result = try? await host.energyManager.setCarChargingMode(
            sensorId: parameters.batteryToCar!.chargingDeviceId,
            carCharging: ControlCarChargingRequest(
                chargingMode: state.batteryToCar?.previousChargingMode ?? ChargingMode.withSolarPower
            )
        )

        host.logDebug(message: "Battery to car: Stopped at battery level \(overviewData.currentBatteryLevel ?? -1) %")
        host.logSuccess()

        return ScenarioState(
            scenario: state.scenario!,
            status: ScenarioStatus.finishedSuccessful,
            nextTaskRun: nil as Date?,
            batteryToCar: nil as ScenarioBatteryToCarState?
        )
    }
}

class ScenarioBatteryToCarParameters: Codable {
    var chargingDeviceId: String
    var minBatteryLevel: Int = 20

    init() {}

    init(chargingDeviceId: String, minBatteryLevel: Int) {
        self.minBatteryLevel = minBatteryLevel
    }
}

class ScenarioBatteryToCarState: Codable {
    var isStarted: Bool = false
    var lastBatteryPercentage: Int? = nil
    var previousChargingMode: ChargingMode? = nil

    init() {
    }

    init(
        isStarted: Bool,
        lastBatteryPercentage: Int?,
        previousChargeMode: ChargingMode
    ) {
        self.isStarted = isStarted
        self.lastBatteryPercentage = lastBatteryPercentage
        self.previousChargingMode = previousChargeMode
    }
}
