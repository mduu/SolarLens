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
        var overviewData = try? await host.energyManager.fetchOverviewData(lastOverviewData: nil)
        guard
            let overviewData = overviewData,
            let currentBatteryLevel = overviewData.currentBatteryLevel
        else {
            host.logError(message: "Battery to car: Unable to fetch overview data")
            return state  // keep current state for retry
        }

        if state.batteryToCar?.lastBatteryPercentage == nil {
            await startScenario(
                host: host,
                parameters: parameters,
                state: state,
                overviewData: overviewData
            )
        }

        let isWorkDone: Bool = currentBatteryLevel <= parameters.batteryToCar!.minBatteryLevel

        if !isWorkDone {
            // Continue scenario and schedule next run
            host.logInfo(message: "Battery to car: scheduled next call")
            return ScenarioState(
                scenario: state.scenario!,
                status: ScenarioStatus.running,
                nextTaskRun: Date().addingTimeInterval(fiveMinutes),
                batteryToCar: ScenarioBatteryToCarState(
                    lastBatteryPercentage: currentBatteryLevel,
                    previousChargingDeviceId: (state.batteryToCar?.previousChargingDeviceId)!,
                    previousChargeMode: state.batteryToCar!.previousChargingMode!
                )
            )
        }

        await stopScenario(
            host: host,
            parameters: parameters,
            state: state,
            overviewData: overviewData
        )

        host.logSuccess()
        return ScenarioState(
            scenario: state.scenario!,
            status: ScenarioStatus.finishedSuccessful,
            nextTaskRun: nil as Date?,
            batteryToCar: nil as ScenarioBatteryToCarState?
        )
    }

    func startScenario(
        host: any ScenarioHost,
        parameters: ScenarioParameters,
        state: ScenarioState,
        overviewData: OverviewData
    ) async {
        host.logDebug(message: "Battery to car: start scenario")

        state.batteryToCar!.lastBatteryPercentage = overviewData.currentBatteryLevel

        // Deactivate car charging if previously activated by scenario

        // TODO Backup previous state

        // TODO Set charging mode

        host.logDebug(message: "Battery to car: Scenario started")
    }

    func stopScenario(
        host: any ScenarioHost,
        parameters: ScenarioParameters,
        state: ScenarioState,
        overviewData: OverviewData
    ) async {
        host.logDebug(message: "Battery to car: stopping scenario")

        guard let previousDeviceId = state.batteryToCar!.previousChargingDeviceId else {
            return
        }

        let previousChargingMode = state.batteryToCar?.previousChargingMode ?? ChargingMode.withSolarPower

        let chargingRequest = ControlCarChargingRequest(
            chargingMode: previousChargingMode
        )

        let result = try? await host.energyManager.setCarChargingMode(
            sensorId: previousDeviceId,
            carCharging: chargingRequest
        )

        host.logDebug(message: "Battery to car: Scenario stopped")
    }

}

class ScenarioBatteryToCarParameters: Codable {
    var minBatteryLevel: Int = 20

    init() {}

    init(minBatteryLevel: Int) {
        self.minBatteryLevel = minBatteryLevel
    }
}

class ScenarioBatteryToCarState: Codable {
    var lastBatteryPercentage: Int? = nil
    var previousChargingDeviceId: String? = nil
    var previousChargingMode: ChargingMode? = nil

    init() {
    }

    init(
        lastBatteryPercentage: Int?,
        previousChargingDeviceId: String,
        previousChargeMode: ChargingMode
    ) {
        self.lastBatteryPercentage = lastBatteryPercentage
        self.previousChargingDeviceId = previousChargingDeviceId
        self.previousChargingMode = previousChargeMode
    }
}
