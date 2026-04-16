internal import Foundation
import SwiftUI

@Observable
class CurrentBuildingState {
    var isLoading = false
    var errorMessage: String?
    var error: EnergyManagerClientError?
    var loginCredentialsExists: Bool = false
    var didLoginSucceed: Bool? = nil
    var overviewData: OverviewData = .init()
    var solarDetailsData: SolarDetailsData?
    var isChangingCarCharger: Bool = false
    var carChargerSetSuccessfully: Bool? = nil
    var isChangingSensorPriority: Bool = false
    var sensorPrioritySetSuccessfully: Bool? = nil
    var isChangingBatteryMode: Bool = false
    var batteryModeSetSuccessfully: Bool? = nil
    var fetchingIsPaused: Bool = false
    var chargingInfos: CharingInfoData?

    private let energyManager: EnergyManager
    private var activeFetchTask: Task<Void, Never>?

    /// Seconds after which a hanging fetch is cancelled at the state layer.
    /// Paired with `viewLoadingTimeoutSeconds` below so that the state layer
    /// always gives up first — leaving a small margin for the defer-driven
    /// `isLoading = false` to propagate before the view checks whether its
    /// own deadline has passed and shows the timeout UI.
    static let fetchTimeoutSeconds: TimeInterval = 30

    /// View-layer timeout for showing the "loading took too long" UI.
    /// Must be strictly greater than `fetchTimeoutSeconds` so the state-layer
    /// cancellation runs first and the view never spins longer than the
    /// state has already given up.
    static let viewLoadingTimeoutSeconds: TimeInterval = fetchTimeoutSeconds + 2

    private struct ChargingModeOverride {
        let sensorId: String
        let mode: ChargingMode
        let timestamp: Date
    }

    private struct BatteryModeOverride {
        let sensorId: String
        let modeInfo: BatteryModeInfo
        let timestamp: Date
    }

    private var chargingModeOverride: ChargingModeOverride?
    private var batteryModeOverride: BatteryModeOverride?
    private let optimisticOverrideTimeout: TimeInterval = 60

    init(energyManagerClient: EnergyManager) {
        self.energyManager = energyManagerClient
        updateCredentialsExists()
    }

    init() {
        self.energyManager = SolarManager.shared
        updateCredentialsExists()
    }

    func pauseFetching() {
        fetchingIsPaused = true
        print("fetching paused")
    }

    func resumeFetching() {
        fetchingIsPaused = false
        print("fetching resumed")
    }

    func tryLogin(email: String, password: String) async {
        didLoginSucceed = await energyManager.login(
            username: email,
            password: password
        )
        updateCredentialsExists()

        if didLoginSucceed == true {
            resetError()
        }
    }

    @MainActor
    func fetchServerData() async {
        if !loginCredentialsExists || fetchingIsPaused { return }

        // If a fetch is already running, await its completion instead of dropping
        if let existingTask = activeFetchTask {
            await existingTask.value
            return
        }

        // Flip state synchronously so callers on the same MainActor never see
        // a render cycle where "a fetch is about to happen" is still rendered
        // as "idle with old data" — that caused the brief "Alte Daten" flash
        // on watch app activation.
        isLoading = true
        resetError()

        let task = Task { @MainActor in
            defer {
                activeFetchTask = nil
                isLoading = false
            }

            do {
                print("Fetching server data...")

                var stopwatch = Stopwatch.init()
                let lastOverviewData = overviewData
                let newData = try await withFetchTimeout(
                    CurrentBuildingState.fetchTimeoutSeconds
                ) { [energyManager] in
                    try await energyManager.fetchOverviewData(
                        lastOverviewData: lastOverviewData
                    )
                }
                stopwatch.stop()

                overviewData = newData
                applyOptimisticOverrides()

                print(
                    "Server data fetched at \(Date()) in \(String(stopwatch.elapsedMilliseconds() ?? 0))ms"
                )
            } catch is CancellationError {
                print("⏱ Fetch timed out after \(CurrentBuildingState.fetchTimeoutSeconds)s")
                self.error = .fetchTimeout
                errorMessage = "Request timed out."
            } catch {
                if error is RestError {
                    self.error = .apiError(apiError: error as! RestError)
                } else {
                    self.error = error as? EnergyManagerClientError
                }
                errorMessage = error.localizedDescription
            }
        }
        activeFetchTask = task
        await task.value
    }

    @MainActor
    func fetchChargingInfos() async {
        if !loginCredentialsExists || isLoading {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            print("\(Date()) - Fetching charing data")

            chargingInfos = try await withFetchTimeout(
                CurrentBuildingState.fetchTimeoutSeconds
            ) { [energyManager] in
                try await energyManager.fetchChargingData()
            }

            print("\(Date()) - Server charging data fetched")
        } catch is CancellationError {
            print("⏱ Charging fetch timed out after \(CurrentBuildingState.fetchTimeoutSeconds)s")
            self.error = .fetchTimeout
            errorMessage = "Request timed out."
        } catch {
            self.error = error as? EnergyManagerClientError
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func fetchSolarDetails() async {
        let fetchedSolarDetailsData = try? await energyManager.fetchSolarDetails()

        guard let fetchedSolarDetailsData else {
            return
        }

        solarDetailsData = fetchedSolarDetailsData
    }

    @MainActor
    func fetchMainDataForToday() async -> MainData? {
        let consumptionData = try? await energyManager.fetchMainData(
            from: Date.todayStartOfDay(),
            to: Date.todayEndOfDay()
        )

        return consumptionData
    }

    @MainActor
    func fetchStatisticsForPast7Days() async -> [DayStatistic]? {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -7, to: Date.todayStartOfDay())

        guard let start else {
            return nil
        }

        let mainData = try? await energyManager.fetchMainData(
            from: start,
            to: Date.todayEndOfDay(),
            interval: 300
        )

        guard let mainData else {
            return nil
        }

        let staticsPerDay: [DayStatistic] = calculateDailyStatistics(dataPoints: mainData.data)

        return staticsPerDay

    }

    private func calculateDailyStatistics(dataPoints: [MainDataItem]) -> [DayStatistic] {
        // Group data points by calendar day
        let calendar = Calendar.current

        // Dictionary to store data points grouped by day
        var dataPointsByDay: [Date: [MainDataItem]] = [:]

        for dataPoint in dataPoints {
            // Get the start of the day for this data point's timestamp
            let dayStart = calendar.startOfDay(for: dataPoint.date)

            if dataPointsByDay[dayStart] == nil {
                dataPointsByDay[dayStart] = []
            }
            dataPointsByDay[dayStart]?.append(dataPoint)
        }

        // Create DayStatistic for each day by aggregating the values
        let dayStatistics = dataPointsByDay.map { (day, itemsForDay) -> DayStatistic in
            return DayStatistic(
                day: day,
                consumption: itemsForDay.reduce(0.0) { $0 + $1.consumptionOverTimeWatthours },
                production: itemsForDay.reduce(0.0) { $0 + $1.productionOverTimeWatthours },
                imported: itemsForDay.reduce(0.0) { $0 + $1.importedOverTimeWhatthours },
                exported: itemsForDay.reduce(0.0) { $0 + $1.exportedOverTimeWhatthours }
            )
        }

        // Sort by day in ascending order
        return dayStatistics.sorted { $0.day < $1.day }
    }

    @MainActor
    func fetchAllimeStatistics() async -> Statistics? {
        return try? await energyManager.fetchStatistics(from: nil, to: Date(), accuracy: .low)
    }

    @MainActor
    func setCarCharging(
        sensorId: String,
        newCarCharging: ControlCarChargingRequest
    ) async {
        guard loginCredentialsExists && !isChangingCarCharger
        else {
            print("WARN: Login-Credentials don't exists or is loading already")
            return
        }

        carChargerSetSuccessfully = nil
        isChangingCarCharger = true
        defer {
            isChangingCarCharger = false
        }

        do {

            resetError()

            print("Set car-changing settings \(Date())")

            let result = try await energyManager.setCarChargingMode(
                sensorId: sensorId,
                carCharging: newCarCharging
            )

            print("Car-Charging set at \(Date())")

            // Optimistic UI: Update charging mode in-memory to speed up UI
            let chargingStation = overviewData.chargingStations
                .first(where: { $0.id == sensorId })
            chargingStation?.chargingMode = newCarCharging.chargingMode
            chargingModeOverride = ChargingModeOverride(
                sensorId: sensorId,
                mode: newCarCharging.chargingMode,
                timestamp: Date()
            )

            carChargerSetSuccessfully = result
            AppStoreReviewManager.shared.setChargingModeSetAtLeastOnce()
        } catch {
            carChargerSetSuccessfully = false
        }
    }

    @MainActor
    func setSensorPriority(sensorId: String, newPriority: Int) async {
        guard loginCredentialsExists && !isChangingSensorPriority
        else {
            print("WARN: Login-Credentials don't exists or is loading already")
            return
        }

        isChangingSensorPriority = true
        defer {
            isChangingSensorPriority = false
        }

        do {

            resetError()

            print(
                "\(Date()): Set sensor \(sensorId) to priority \(newPriority)"
            )

            _ = try await energyManager.setSensorPriority(
                sensorId: sensorId,
                priority: newPriority
            )

            print(
                "\(Date()): Sensor \(sensorId) priority se to \(newPriority)."
            )

            await fetchServerData()

            sensorPrioritySetSuccessfully = true
            AppStoreReviewManager.shared.setChargingModeSetAtLeastOnce()
        } catch {
            sensorPrioritySetSuccessfully = false
        }
    }

    @MainActor
    func setBatteryMode(
        sensorId: String,
        batteryModeInfo: BatteryModeInfo
    ) async {
        guard loginCredentialsExists && !isChangingBatteryMode
        else {
            print("WARN: Login-Credentials don't exists or is changing already")
            return
        }

        batteryModeSetSuccessfully = nil
        isChangingBatteryMode = true
        defer {
            isChangingBatteryMode = false
        }

        do {

            resetError()

            print("Set battery mode \(Date())")

            let result = try await energyManager.setBatteryMode(
                sensorId: sensorId,
                batteryModeInfo: batteryModeInfo
            )

            print("Battery-Mode set at \(Date())")

            // Optimistic UI: Update battery mode in-memory to speed up UI
            let batteryDevice = overviewData.devices
                .first(where: { $0.id == sensorId })
            batteryDevice?.batteryInfo = BatteryInfo(
                favorite: batteryDevice?.batteryInfo?.favorite ?? true,
                maxDischargePower: batteryDevice?.batteryInfo?.maxDischargePower ?? 0,
                maxChargePower: batteryDevice?.batteryInfo?.maxChargePower ?? 0,
                batteryCapacityKwh: batteryDevice?.batteryInfo?.batteryCapacityKwh ?? 0,
                modeInfo: batteryModeInfo
            )
            batteryModeOverride = BatteryModeOverride(
                sensorId: sensorId,
                modeInfo: batteryModeInfo,
                timestamp: Date()
            )

            batteryModeSetSuccessfully = result
            AppStoreReviewManager.shared.setBatterModeSetAtLeastOnce()
        } catch {
            batteryModeSetSuccessfully = false
        }
    }

    @MainActor
    func logout() {
        KeychainHelper.deleteCredentials()
        updateCredentialsExists()
        resetError()
    }

    @MainActor
    func checkForCredentions() {
        updateCredentialsExists()
    }

    private func updateCredentialsExists() {
        let credentials = KeychainHelper.loadCredentials()

        loginCredentialsExists =
            credentials.username?.isEmpty == false
            && credentials.password?.isEmpty == false
    }

    private func applyOptimisticOverrides() {
        let now = Date()

        if let override = chargingModeOverride {
            let station = overviewData.chargingStations
                .first(where: { $0.id == override.sensorId })
            if now.timeIntervalSince(override.timestamp) < optimisticOverrideTimeout,
               station?.chargingMode != override.mode {
                station?.chargingMode = override.mode
            } else {
                chargingModeOverride = nil
            }
        }

        if let override = batteryModeOverride {
            let device = overviewData.devices
                .first(where: { $0.id == override.sensorId })
            if now.timeIntervalSince(override.timestamp) < optimisticOverrideTimeout,
               device?.batteryInfo?.modeInfo.batteryMode != override.modeInfo.batteryMode {
                if let existing = device?.batteryInfo {
                    device?.batteryInfo = BatteryInfo(
                        favorite: existing.favorite,
                        maxDischargePower: existing.maxDischargePower,
                        maxChargePower: existing.maxChargePower,
                        batteryCapacityKwh: existing.batteryCapacityKwh,
                        modeInfo: override.modeInfo
                    )
                }
            } else {
                batteryModeOverride = nil
            }
        }
    }

    private func resetError() {
        errorMessage = nil
        error = nil
    }
}

extension CurrentBuildingState {
    
    static func fake() -> CurrentBuildingState {
        return .fake(overviewData: .fake())
    }

    static func fake(
        overviewData: OverviewData = OverviewData.fake(),
        loggedIn: Bool = true,
        isLoading: Bool = false,
        didLoginSucceed: Bool? = nil,
        error: EnergyManagerClientError? = nil,
        errorMessage: String? = nil
    ) -> CurrentBuildingState {
        let result = CurrentBuildingState.init(
            energyManagerClient: FakeEnergyManager.init(data: overviewData)
        )
        result.isLoading = false
        result.loginCredentialsExists = loggedIn

        Task {
            await result.fetchServerData()
        }

        result.isLoading = isLoading
        result.didLoginSucceed = didLoginSucceed
        result.error = error
        result.errorMessage = errorMessage

        return result
    }

}
