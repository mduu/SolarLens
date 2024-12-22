import Foundation

@MainActor
class SolarChartViewModel: ObservableObject {
    @Published var consumptionData: ConsumptionData? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var error: EnergyManagerClientError? = nil

    private let energyManager: EnergyManager
    private var solarChartLastFetchAt: Date?

    init(energyManagerClient: EnergyManager = SolarManager.instance) {
        self.energyManager = energyManagerClient
    }

    public static func previewFake() -> SolarChartViewModel {
        let fakeEnergyManager = FakeEnergyManager.init()

        return SolarChartViewModel.init(energyManagerClient: fakeEnergyManager)
    }

    public func fetch() async {
        if isLoading {
            return
        }

        do {
            isLoading = true

            if solarChartLastFetchAt == nil
                || Date().timeIntervalSince(solarChartLastFetchAt!) > 60
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

                var consumptionData = try await energyManager.fetchConsumptions(
                    from: Calendar.current.startOfDay(for: .now),
                    to: toDate)

                if consumptionData.data.count == 0 {
                    self.errorMessage =
                        "Failed to fetch consumption data from server."
                    self.error = .invalidData
                    self.isLoading = false
                    return
                }

                self.consumptionData = trimEmptyAtDayStart(from: consumptionData)
                solarChartLastFetchAt = Date()

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

    private func trimEmptyAtDayStart(from consumptionData: ConsumptionData)
        -> ConsumptionData
    {
        let data = consumptionData.data

        // Find first non-zero index
        guard let firstNonZeroIndex = data.firstIndex(where: { $0.productionWatts > 0 })
        else {
            return consumptionData
        }

        // Find last non-zero index, starting from the end
        let lastNonZeroIndex = data.lastIndex(where: { $0.productionWatts > 0 }) ?? data.endIndex
        
        consumptionData.data = Array(data[firstNonZeroIndex...lastNonZeroIndex])
        
        return consumptionData
    }
}
