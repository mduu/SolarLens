internal import Foundation

@Observable()
class ChartViewModel: ObservableObject {
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

    public static func previewFake() -> ChartViewModel {
        let fakeEnergyManager = FakeEnergyManager.init()

        return ChartViewModel.init(energyManagerClient: fakeEnergyManager)
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

                let calendar = Calendar.current
                let now = Date()
                let components = calendar.dateComponents(
                    [.year, .month, .day], from: now)
                let endOfDayComponents = DateComponents(
                    year: components.year, month: components.month,
                    day: components.day,
                    hour: 23, minute: 59, second: 59)
                let toDate = calendar.date(from: endOfDayComponents)!

                let consumptionData = try await energyManager.fetchMainData(
                    from: Calendar.current.startOfDay(for: .now),
                    to: toDate)

                if consumptionData.data.count == 0 {
                    self.errorMessage =
                        "Failed to fetch consumption data from server."
                    self.error = .invalidData
                    self.isLoading = false
                    return
                }

                self.consumptionData = consumptionData
                consumptionChartLastFetchAt = Date()

                print("Fetched consumption data from server successfully.")
            }
            
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
