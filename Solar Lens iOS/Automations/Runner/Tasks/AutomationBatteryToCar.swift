internal import Foundation
internal import UserNotifications

/// Automation: drain the house battery (and only the house battery) into the
/// car. Sets the wallbox to *Constant current* at an amperage matched to the
/// battery's max discharge, monitors and re-tunes every tick, stops just
/// before the user-chosen soft floor or when grid import becomes unavoidable.
final class AutomationBatteryToCar: AutomationTask {
    public static let shared = AutomationBatteryToCar()

    let automationName: LocalizedStringResource = "Battery to Car"
    private let monitorInterval: TimeInterval = 60

    /// Window inside which we treat the predicted soft-floor crossing as
    /// "imminent" and schedule a calendar-triggered fallback
    /// notification. The forecast is a linear extrapolation from
    /// instantaneous discharge — it can be very wrong further out, so
    /// we ONLY trust it within this short window. The regular tick
    /// cadence is unaffected: we keep polling on `monitorInterval` (and
    /// whatever iOS gives us in BG, typically ~7 min) so that the
    /// predictive notification is just a backstop, not a replacement.
    private let imminentForecastWindow: TimeInterval = 15 * 60

    /// Identifier used for the pre-scheduled "soft floor due" local
    /// notification. Stable so we can replace / cancel it across ticks.
    static let softFloorDueNotificationId =
        "automation.batteryToCar.softFloorDue"

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
            host.logDebug(
                message:
                    "Battery to Car: telemetry fetch failed — keeping current settings, will retry next tick"
            )
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

        return scheduleNextTickConsideringForecast(
            host: host,
            params: params,
            telemetry: t,
            liveState: liveState,
            in: state
        )
    }

    /// Picks the next tick time and, when the floor is imminent,
    /// pre-arms a calendar-triggered fallback notification.
    ///
    /// `nextTaskRun` is **always** the regular monitor interval — the
    /// linear forecast is just an extrapolation from instantaneous
    /// discharge and can be wildly wrong further out (clouds clear, a
    /// load drops, etc.), so we never let it dictate when we re-check.
    /// The pre-scheduled notification is a pure backstop: if iOS
    /// doesn't grant us BG runtime in time and the forecast turns out
    /// right, the user still gets nudged at the predicted moment. If
    /// the forecast moves further out on the next tick, the
    /// notification is cancelled and re-scheduled (or dropped).
    private func scheduleNextTickConsideringForecast(
        host: any AutomationHost,
        params: AutomationBatteryToCarParameters,
        telemetry t: Telemetry,
        liveState: AutomationBatteryToCarState,
        in fullState: AutomationState
    ) -> AutomationState {
        let regularNext = Date().addingTimeInterval(monitorInterval)

        // Capture the forecast on EVERY tick (not just within the
        // imminent window) so the in-app card and Live Activity can
        // display an ETA whenever it's available. The notification
        // backstop is still gated on the imminent window.
        let secondsToFloor = t.overview.forecastSeconds(
            toReach: params.minBatteryLevel
        )

        var liveState = liveState
        liveState.forecastedFloorAt = secondsToFloor.flatMap {
            $0 > 0 ? Date().addingTimeInterval($0) : nil
        }

        if let s = secondsToFloor, s > 0, s <= imminentForecastWindow {
            scheduleSoftFloorDueNotification(
                at: Date().addingTimeInterval(s),
                floorPct: params.minBatteryLevel
            )
            host.logDebug(
                message:
                    "Battery to Car: floor forecast in \(Int(s))s — pre-scheduling backstop notification (regular tick cadence unchanged)"
            )
        } else {
            cancelSoftFloorDueNotification()
        }

        return AutomationState(
            automation: fullState.automation!,
            status: .running,
            nextTaskRun: regularNext,
            batteryToCar: liveState
        )
    }

    // MARK: - Soft-floor pre-scheduled notification

    private func scheduleSoftFloorDueNotification(
        at date: Date,
        floorPct: Int
    ) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Battery → Car heads-up")
        content.body = String(
            localized:
                "Battery is approaching the \(floorPct)% floor — open Solar Lens to apply your fallback charging mode."
        )
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier =
            AutomationNotificationDelegate.openHomeCategoryId
        content.userInfo = [
            AutomationNotificationDelegate.deepLinkUserInfoKey:
                "solarlens://automation",
        ]

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: comps,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: Self.softFloorDueNotificationId,
            content: content,
            trigger: trigger
        )

        Task {
            // Replace any prior pre-scheduled notification (forecast may
            // have moved since the previous tick). `add` overwrites by
            // identifier, but explicit cancel keeps the model clear.
            center.removePendingNotificationRequests(
                withIdentifiers: [Self.softFloorDueNotificationId]
            )
            try? await center.add(request)
        }
    }

    private func cancelSoftFloorDueNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [Self.softFloorDueNotificationId]
            )
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
                message:
                    "Battery to Car: fetch overview failed (\(error.localizedDescription)); will retry next tick"
            )
            return nil
        }

        guard let soc = overview.currentBatteryLevel else {
            host.logError(
                message:
                    "Battery to Car: no battery level reading from house battery; cannot tick"
            )
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
                graceW: AmperageRamp.defaultGraceW,
                smoothedTickIntervalMinutes:
                    liveState.smoothedTickIntervalMinutes
            )
        )

        guard newAmps != liveState.currentAmps else { return }

        let throttling = AmperageRamp.backgroundThrottlingActive(
            smoothedTickIntervalMinutes:
                liveState.smoothedTickIntervalMinutes
        )
        let intervalMin = String(
            format: "%.1f",
            liveState.smoothedTickIntervalMinutes
        )
        if throttling && newAmps < liveState.currentAmps {
            host.logInfo(
                message:
                    "Battery to Car: ramp \(liveState.currentAmps) A → \(newAmps) A (BG-throttling slowdown — avg tick \(intervalMin) min, grid \(t.gridImportW) W)"
            )
        } else {
            host.logDebug(
                message:
                    "Battery to Car: ramp \(liveState.currentAmps) A → \(newAmps) A (grid \(t.gridImportW) W, avg tick \(intervalMin) min)"
            )
        }
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
                message:
                    "Battery to Car: ramp \(liveState.currentAmps) A → \(newAmps) A failed (\(error.localizedDescription)); keeping \(liveState.currentAmps) A, will retry next tick"
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

        guard let station = t.station else {
            host.logError(
                message:
                    "Battery to Car: charging station id \(params.chargingDeviceId) not found in overview; cannot start"
            )
            host.logFailure()
            return state.failed()
        }
        let previousMode = station.chargingMode

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
            host.logError(
                message:
                    "Battery to Car: failed to set wallbox to constant current \(initialAmps) A: \(error.localizedDescription)"
            )
            host.logFailure()
            return state.failed()
        }

        let fallbackName = String(
            localized: params.fallbackChargingMode.localizedTitle
        )
        let phasesName = String(localized: params.phases.localizedTitle)
        let previousModeName = String(localized: previousMode.localizedTitle)
        host.logInfo(
            message:
                "Battery to Car: started at \(initialAmps) A, battery \(t.currentBatteryLevel)% — floor \(params.minBatteryLevel)%, fallback after run: \(fallbackName)"
        )
        host.logDebug(
            message:
                "Battery to Car: setup — wallbox \(phasesName), previous wallbox mode \(previousModeName), battery capacity \(String(format: "%.1f", t.totalBatteryCapacityKwh)) kWh, max discharge \(t.totalMaxDischargeW) W"
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
        let fallbackName = String(
            localized: params.fallbackChargingMode.localizedTitle
        )
        let reasonName = describe(stopReason: liveState.stopReason)
        host.logDebug(
            message:
                "Battery to Car: stop triggered (\(reasonName)) — switching wallbox to \(fallbackName)"
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
                message:
                    "Battery to Car: failed to switch wallbox to fallback mode \(fallbackName): \(error.localizedDescription) — wallbox may stay on constant current. Please check the Solar Manager app."
            )
        }

        var stopped = liveState
        stopped.endSoc = t.currentBatteryLevel

        host.logInfo(
            message:
                "Battery to Car: stopped at \(t.currentBatteryLevel)% (\(reasonName)) — transferred ≈ \(String(format: "%.2f", stopped.kWhTransferred)) kWh, wallbox switched to \(fallbackName)"
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

    /// Human-readable reason for the automation log. Not localised because
    /// log messages are diagnostic in nature; the user-facing notification
    /// string is composed separately by `AutomationManager`.
    private func describe(
        stopReason: AutomationBatteryToCarStopReason?
    ) -> String {
        switch stopReason {
        case .softFloorReached: return "soft floor reached"
        case .capped:           return "grid import unavoidable at minimum amps"
        case .cancelled:        return "cancelled by user"
        case .none:             return "unknown reason"
        }
    }
}

// MARK: - Parameters & state
//
// Codable model structs (`AutomationBatteryToCarParameters`,
// `AutomationBatteryToCarState`, `AutomationBatteryToCarStopReason`) live
// in `Shared/Services/Automations/AutomationBatteryToCarParameters.swift`
// so the watch app can decode them over WatchConnectivity.
