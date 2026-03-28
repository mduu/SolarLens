internal import Foundation

@Observable
class BatteryChartViewModel {
    var mainData: MainData?
    var batteryHistory: [BatteryHistory]?
    var isLoading = false
    var errorMessage: String?
    var error: EnergyManagerClientError?

    private let energyManager: EnergyManager
    private var lastFetchAt: Date?

    init(energyManagerClient: EnergyManager = SolarManager.shared) {
        self.energyManager = energyManagerClient
    }

    static func previewFake() -> BatteryChartViewModel {
        BatteryChartViewModel(energyManagerClient: FakeEnergyManager())
    }

    @MainActor
    func fetch() async {
        if isLoading { return }

        do {
            isLoading = true

            if lastFetchAt == nil
                || Date().timeIntervalSince(lastFetchAt!) > 60
            {
                async let mainDataTask = energyManager.fetchMainData(
                    from: Date.todayStartOfDay(),
                    to: Date.todayEndOfDay()
                )
                async let batteryTask = energyManager.fetchTodaysBatteryHistory()

                let (fetchedMain, fetchedBattery) = try await (mainDataTask, batteryTask)

                if fetchedMain.data.isEmpty {
                    self.errorMessage = "No battery data available."
                    self.error = .invalidData
                    self.isLoading = false
                    return
                }

                self.mainData = fetchedMain
                self.batteryHistory = fetchedBattery
                lastFetchAt = Date()
            }

            errorMessage = nil
            error = nil
            isLoading = false

        } catch {
            self.error = error as? EnergyManagerClientError
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
