internal import Foundation

@Observable()
class OverviewChartViewModel: ObservableObject {
    var consumptionData: MainData? = nil
    var batteryHistory: [BatteryHistory]?
    var isLoading = false
    var errorMessage: String? = nil
    var error: EnergyManagerClientError? = nil

    private let energyManager: EnergyManager
    private var consumptionChartLastFetchAt: Date?

    init(energyManagerClient: EnergyManager = SolarManager.instance()) {
        self.energyManager = energyManagerClient
    }

    public static func previewFake() -> OverviewChartViewModel {
        let fakeEnergyManager = FakeEnergyManager.init()

        return OverviewChartViewModel.init(
            energyManagerClient: fakeEnergyManager
        )
    }

    public func fetch() async {
        if isLoading {
            return
        }

        do {
            isLoading = true

            if consumptionChartLastFetchAt == nil
                || Date().timeIntervalSince(consumptionChartLastFetchAt!) > 60
            {
                print("Fetching consumption data server data...")

                let consumptionData = try await energyManager.fetchMainData(
                    from: Date.todayStartOfDay(),
                    to: Date.todayEndOfDay()
                )

                if consumptionData.data.count == 0 {
                    self.errorMessage =
                        "Failed to fetch consumption data from server."
                    self.error = .invalidData
                    self.isLoading = false
                    return
                }

                self.consumptionData = consumptionData

                let batteryHistory =
                    try? await energyManager.fetchTodaysBatteryHistory()
                if batteryHistory == nil || batteryHistory?.count == 0 {
                    self.errorMessage =
                        "Failed to fetch battery history data from server."
                    self.error = .invalidData
                    self.batteryHistory = []
                } else {
                    self.batteryHistory = batteryHistory
                }

                consumptionChartLastFetchAt = Date()

                print("Fetched consumption data from server successfully.")
            }

            errorMessage = nil
            self.error = nil

            print("Server solar-details data fetched at \(Date())")

            isLoading = false

        } catch {
            self.error = error as? EnergyManagerClientError
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
