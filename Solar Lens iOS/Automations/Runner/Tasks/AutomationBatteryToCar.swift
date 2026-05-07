internal import Foundation

/// Automation: drain the house battery (and only the house battery) into the
/// car. Sets the wallbox to *Constant current* at an amperage matched to the
/// battery's max discharge, monitors and re-tunes every tick, stops just
/// before the user-chosen soft floor or when grid import becomes unavoidable.
final class AutomationBatteryToCar: AutomationTask {
    public static let shared = AutomationBatteryToCar()

    let automationName: LocalizedStringResource = "Battery to Car"
    private let monitorInterval: TimeInterval = 60

    func run(
        host: any AutomationHost,
        parameters: AutomationParameters,
        state: AutomationState
    ) async throws -> AutomationState {
        guard let params = parameters.batteryToCar,
              let liveState0 = state.batteryToCar else {
            host.logError(message: "Battery to Car: missing parameters")
            host.logFailure()
            return state.failed()
        }

        guard let t = await fetchTelemetry(
            host: host, params: params
        ) else {
            return scheduleNextTick(state: liveState0, in: state)
        }

        // First tick of this run: set up the wallbox + capture starting SoC.
        if !liveState0.isStarted {
            return await startRun(
                host: host, parameters: params,
                state: state, telemetry: t
            )
        }

        var liveState = updateTickMetrics(liveState0, with: t)
        accumulateTransferredKWh(
            &liveState, with: t, previousTickAt: liveState0.lastTickAt
        )

        // Stop condition (a): predictive soft-floor reached.
        if shouldStopOnSoftFloor(
            liveState: liveState, params: params, telemetry: t
        ) {
            liveState.stopReason = .softFloorReached
            return await stopRun(
                host: host, parameters: params,
                state: state, liveState: liveState, telemetry: t
            )
        }

        // Stop condition (b): grid import sustained at minimum amps.
        if updateGridCapStreakAndShouldStop(&liveState, telemetry: t) {
            liveState.stopReason = .capped
            return await stopRun(
                host: host, parameters: params,
                state: state, liveState: liveState, telemetry: t
            )
        }

        await retuneAmperage(
            host: host, params: params,
            telemetry: t, liveState: &liveState
        )

        return scheduleNextTick(state: liveState, in: state)
    }

    // MARK: - Telemetry

    /// Per-tick derived data, computed once and passed down so each step
    /// doesn't have to reach back into the OverviewData.
    private struct Telemetry {
        let overview: OverviewData
        let now: Date
        let currentBatteryLevel: Int
        let totalBatteryCapacityKwh: Double
        let totalMaxDischargeW: Int
        /// Signed battery flow: + = charging from PV surplus, − = discharging.
        let batteryChargeRateW: Int
        /// Convenience: discharge magnitude. Equal to max(0, −batteryChargeRateW).
        let dischargeW: Int
        let gridImportW: Int
        let station: ChargingStation?
    }

    private func fetchTelemetry(
        host: any AutomationHost,
        params: AutomationBatteryToCarParameters
    ) async -> Telemetry? {
        let overview: OverviewData
        do {
            overview = try await host.energyManager
                .fetchOverviewData(lastOverviewData: nil)
        } catch {
            host.logError(
                message: "Battery to Car: fetch overview failed; will retry"
            )
            return nil
        }

        guard let soc = overview.currentBatteryLevel else {
            host.logError(message: "Battery to Car: no battery level reading")
            return nil
        }

        let batteries: [Device] = overview.devices.filter {
            $0.deviceType == .battery && $0.batteryInfo != nil
        }
        let totalBatteryCapacityKwh: Double = batteries.reduce(0.0) {
            (acc: Double, dev: Device) in
            acc + (dev.batteryInfo?.batteryCapacityKwh ?? 0)
        }
        let totalMaxDischargeW: Int = batteries.reduce(0) {
            (acc: Int, dev: Device) in
            acc + (dev.batteryInfo?.maxDischargePower ?? 0)
        }

        let chargeRateW = overview.currentBatteryChargeRate ?? 0
        return Telemetry(
            overview: overview,
            now: Date(),
            currentBatteryLevel: soc,
            totalBatteryCapacityKwh: totalBatteryCapacityKwh,
            totalMaxDischargeW: totalMaxDischargeW,
            batteryChargeRateW: chargeRateW,
            dischargeW: max(0, -chargeRateW),
            gridImportW: overview.currentGridToHouse,
            station: overview.chargingStations
                .first { $0.id == params.chargingDeviceId }
        )
    }

    // MARK: - Tick steps

    private func updateTickMetrics(
        _ liveState: AutomationBatteryToCarState,
        with t: Telemetry
    ) -> AutomationBatteryToCarState {
        var s = liveState
        if let last = s.lastTickAt {
            let observedMin = t.now.timeIntervalSince(last) / 60.0
            s.smoothedTickIntervalMinutes = SoftFloor.updatedTickInterval(
                previousMinutes: s.smoothedTickIntervalMinutes,
                observedMinutes: observedMin
            )
        }
        s.lastTickAt = t.now
        s.lastBatteryPercentage = t.currentBatteryLevel
        return s
    }

    private func accumulateTransferredKWh(
        _ liveState: inout AutomationBatteryToCarState,
        with t: Telemetry,
        previousTickAt: Date?
    ) {
        guard let station = t.station,
              let prev = previousTickAt else { return }
        let dtH = t.now.timeIntervalSince(prev) / 3600.0
        liveState.kWhTransferred +=
            Double(station.currentPower) / 1000.0 * dtH
    }

    private func shouldStopOnSoftFloor(
        liveState: AutomationBatteryToCarState,
        params: AutomationBatteryToCarParameters,
        telemetry t: Telemetry
    ) -> Bool {
        let safetyBufferPct = SoftFloor.computeSafetyBuffer(
            dischargeW: t.dischargeW,
            batteryCapacityKwh: t.totalBatteryCapacityKwh,
            smoothedTickIntervalMinutes:
                liveState.smoothedTickIntervalMinutes
        )
        return Double(t.currentBatteryLevel) - safetyBufferPct
            <= Double(params.minBatteryLevel)
    }

    /// Bumps the grid-import streak when at min amps and importing, resets
    /// it otherwise. Returns true once the streak hits the cap threshold.
    private func updateGridCapStreakAndShouldStop(
        _ liveState: inout AutomationBatteryToCarState,
        telemetry t: Telemetry
    ) -> Bool {
        let atMinAmps = liveState.currentAmps <= PowerToAmps.minAmps
        let importingAboveGrace = t.gridImportW
            > AmperageRamp.defaultGraceW
        if atMinAmps && importingAboveGrace {
            liveState.gridImportStreak += 1
            return liveState.gridImportStreak >= 2
        }
        liveState.gridImportStreak = 0
        return false
    }

    private func retuneAmperage(
        host: any AutomationHost,
        params: AutomationBatteryToCarParameters,
        telemetry t: Telemetry,
        liveState: inout AutomationBatteryToCarState
    ) async {
        let observedWattsPerAmp: Double? = {
            guard liveState.currentAmps > 0,
                  let station = t.station,
                  station.currentPower > 100 else { return nil }
            return Double(station.currentPower)
                / Double(liveState.currentAmps)
        }()

        let newAmps = AmperageRamp.compute(
            .init(
                currentAmps: liveState.currentAmps,
                gridImportW: t.gridImportW,
                gridExportW: t.overview.currentSolarToGrid,
                batteryChargeRateW: t.batteryChargeRateW,
                batteryMaxDischargeW: t.totalMaxDischargeW,
                phases: params.phases,
                observedWattsPerAmp: observedWattsPerAmp,
                graceW: AmperageRamp.defaultGraceW
            )
        )

        guard newAmps != liveState.currentAmps else { return }

        host.logDebug(
            message:
                "Battery to Car: ramp \(liveState.currentAmps) A → \(newAmps) A (grid \(t.gridImportW) W)"
        )
        do {
            _ = try await host.energyManager.setCarChargingMode(
                sensorId: params.chargingDeviceId,
                carCharging: ControlCarChargingRequest(
                    constantCurrent: newAmps
                )
            )
            liveState.currentAmps = newAmps
        } catch {
            host.logError(
                message: "Battery to Car: ramp failed; retrying next tick"
            )
        }
    }

    // MARK: - Start

    private func startRun(
        host: any AutomationHost,
        parameters params: AutomationBatteryToCarParameters,
        state: AutomationState,
        telemetry t: Telemetry
    ) async -> AutomationState {
        host.logDebug(message: "Battery to Car: starting")

        guard let previousMode = t.station?.chargingMode else {
            host.logError(message: "Battery to Car: charging station not found")
            host.logFailure()
            return state.failed()
        }

        // Start conservative: at the wallbox protocol minimum (6 A) so we
        // can never overshoot a household with already-running loads. The
        // controller ramps up by 1 A per tick when grid export proves there
        // is true surplus to absorb.
        let initialAmps = PowerToAmps.minAmps

        do {
            _ = try await host.energyManager.setCarChargingMode(
                sensorId: params.chargingDeviceId,
                carCharging: ControlCarChargingRequest(
                    constantCurrent: initialAmps
                )
            )
        } catch {
            host.logError(message: "Battery to Car: failed to set initial mode")
            host.logFailure()
            return state.failed()
        }

        host.logInfo(
            message: "Battery to Car: started at \(initialAmps) A, battery \(t.currentBatteryLevel)%"
        )

        return AutomationState(
            automation: state.automation!,
            status: .running,
            nextTaskRun: t.now.addingTimeInterval(monitorInterval),
            batteryToCar: AutomationBatteryToCarState(
                isStarted: true,
                startSoc: t.currentBatteryLevel,
                lastBatteryPercentage: t.currentBatteryLevel,
                previousChargingMode: previousMode,
                currentAmps: initialAmps,
                kWhTransferred: 0,
                lastTickAt: t.now,
                gridImportStreak: 0,
                smoothedTickIntervalMinutes: 1.0,
                stopReason: nil
            )
        )
    }

    // MARK: - Stop

    private func stopRun(
        host: any AutomationHost,
        parameters params: AutomationBatteryToCarParameters,
        state: AutomationState,
        liveState: AutomationBatteryToCarState,
        telemetry t: Telemetry
    ) async -> AutomationState {
        host.logDebug(
            message: "Battery to Car: stopping, switching to fallback mode"
        )

        do {
            _ = try await host.energyManager.setCarChargingMode(
                sensorId: params.chargingDeviceId,
                carCharging: ControlCarChargingRequest(
                    chargingMode: params.fallbackChargingMode
                )
            )
        } catch {
            host.logError(
                message: "Battery to Car: failed to set fallback mode"
            )
        }

        var stopped = liveState
        stopped.endSoc = t.currentBatteryLevel

        host.logInfo(
            message:
                "Battery to Car: stopped at \(t.currentBatteryLevel)%, transferred ≈ \(String(format: "%.2f", stopped.kWhTransferred)) kWh"
        )
        host.logSuccess()

        return AutomationState(
            automation: state.automation!,
            status: .finishedSuccessful,
            nextTaskRun: nil,
            batteryToCar: stopped
        )
    }

    private func scheduleNextTick(
        state liveState: AutomationBatteryToCarState,
        in fullState: AutomationState
    ) -> AutomationState {
        AutomationState(
            automation: fullState.automation!,
            status: .running,
            nextTaskRun: Date().addingTimeInterval(monitorInterval),
            batteryToCar: liveState
        )
    }
}

// MARK: - Parameters & state

struct AutomationBatteryToCarParameters: Codable {
    var chargingDeviceId: String = ""
    var minBatteryLevel: Int = 30
    var fallbackChargingMode: ChargingMode = .withSolarPower
    var phases: WallboxPhases = .three

    init() {}

    init(
        chargingDeviceId: String,
        minBatteryLevel: Int,
        fallbackChargingMode: ChargingMode,
        phases: WallboxPhases = .three
    ) {
        self.chargingDeviceId = chargingDeviceId
        self.minBatteryLevel = minBatteryLevel
        self.fallbackChargingMode = fallbackChargingMode
        self.phases = phases
    }
}

enum AutomationBatteryToCarStopReason: String, Codable {
    case softFloorReached
    case capped
    case cancelled
}

struct AutomationBatteryToCarState: Codable {
    var isStarted: Bool = false
    var startSoc: Int = 0
    var endSoc: Int? = nil
    var lastBatteryPercentage: Int? = nil
    var previousChargingMode: ChargingMode? = nil
    var currentAmps: Int = PowerToAmps.minAmps
    var kWhTransferred: Double = 0
    var lastTickAt: Date? = nil
    var gridImportStreak: Int = 0
    var smoothedTickIntervalMinutes: Double = 1.0
    var stopReason: AutomationBatteryToCarStopReason? = nil

    init() {}

    init(
        isStarted: Bool,
        startSoc: Int,
        lastBatteryPercentage: Int?,
        previousChargingMode: ChargingMode,
        currentAmps: Int,
        kWhTransferred: Double,
        lastTickAt: Date?,
        gridImportStreak: Int,
        smoothedTickIntervalMinutes: Double,
        stopReason: AutomationBatteryToCarStopReason?
    ) {
        self.isStarted = isStarted
        self.startSoc = startSoc
        self.lastBatteryPercentage = lastBatteryPercentage
        self.previousChargingMode = previousChargingMode
        self.currentAmps = currentAmps
        self.kWhTransferred = kWhTransferred
        self.lastTickAt = lastTickAt
        self.gridImportStreak = gridImportStreak
        self.smoothedTickIntervalMinutes = smoothedTickIntervalMinutes
        self.stopReason = stopReason
    }
}
