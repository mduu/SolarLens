import Foundation
import SwiftUI

@Observable
class SolarDetailsViewModel {
    var isLoading = false
    var fetchingIsPaused: Bool = false
    var errorMessage: String?
    var error: EnergyManagerClientError?
    var overviewData: OverviewData = .init()
    var solarDetailsData: SolarDetailsData = .init()

    private let energyManager: EnergyManager
    private var solarDetailsLastFetchAt: Date?

    init(energyManagerClient: EnergyManager = SolarManager.instance()) {
        self.energyManager = energyManagerClient
    }

    public static func previewFake() -> SolarDetailsViewModel {
        let fakeEnergyManager = FakeEnergyManager.init()

        return SolarDetailsViewModel.init(
            energyManagerClient: fakeEnergyManager)
    }

    public func fetchSolarDetails() async {
        if isLoading || fetchingIsPaused {
            return
        }

        do {
            isLoading = true

            if overviewData.lastUpdated == nil
                || Date().timeIntervalSince(overviewData.lastUpdated!) > 30
            {
                print("Fetching overview-details server data...")

                overviewData = try await energyManager.fetchOverviewData(
                    lastOverviewData: overviewData)
         
                print("Server overview-details data fetched at \(Date())")
            }

            if solarDetailsLastFetchAt == nil
                || Date().timeIntervalSince(solarDetailsLastFetchAt!) > 60 * 30
            {
                print("Fetching solar-details server data...")

                let result = try? await energyManager.fetchSolarDetails()
                if result != nil {
                    solarDetailsData = result!
                    solarDetailsLastFetchAt = Date()
                }
                
                print("Server solar-details data fetched at \(Date())")
            }

            errorMessage = nil
            self.error = nil
            isLoading = false
        } catch {
            self.error = error as? EnergyManagerClientError
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
