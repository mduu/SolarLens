import Foundation

@MainActor
class SolarDetailsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var fetchingIsPaused: Bool = false
    @Published var errorMessage: String?
    @Published var error: EnergyManagerClientError?
    @Published var overviewData: OverviewData = .init()
    @Published var solarDetailsData: SolarDetailsData = .init()

    private let energyManager: EnergyManager

    init(energyManagerClient: EnergyManager = SolarManager.instance) {
        self.energyManager = energyManagerClient
    }
    
    public static func previewFake() -> SolarDetailsViewModel {
        let fakeEnergyManager = FakeEnergyManager.init()
        
        return SolarDetailsViewModel.init(energyManagerClient: fakeEnergyManager)
    }

    public func fetchSolarDetails() async {
        if isLoading || fetchingIsPaused {
            return
        }

        do {
            isLoading = true

            print("Fetching solar-details server data...")

            overviewData = try await energyManager.fetchOverviewData(
                lastOverviewData: overviewData)

            let result = try? await energyManager.fetchSolarDetails()
            if result != nil {
                solarDetailsData = result!
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
