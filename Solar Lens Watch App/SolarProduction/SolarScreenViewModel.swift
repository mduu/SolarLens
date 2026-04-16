internal import Foundation
import SwiftUI

@Observable
class SolarScreenViewModel {
    var isLoading = false
    var fetchingIsPaused: Bool = false
    var errorMessage: String?
    var error: EnergyManagerClientError?
    var overviewData: OverviewData = .init()
    var solarDetailsData: SolarDetailsData = .init()

    private let energyManager: EnergyManager
    private var solarDetailsLastFetchAt: Date?

    init(energyManagerClient: EnergyManager = SolarManager.shared) {
        self.energyManager = energyManagerClient
    }

    public static func previewFake() -> SolarScreenViewModel {
        let fakeEnergyManager = FakeEnergyManager.init()

        return SolarScreenViewModel.init(
            energyManagerClient: fakeEnergyManager)
    }

    public func fetchSolarDetails() async {
        if isLoading || fetchingIsPaused {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if overviewData.lastUpdated == nil
                || Date().timeIntervalSince(overviewData.lastUpdated!) > 30
            {
                print("Fetching overview-details server data...")

                let lastOverviewData = overviewData
                overviewData = try await withFetchTimeout(
                    CurrentBuildingState.fetchTimeoutSeconds
                ) { [energyManager] in
                    try await energyManager.fetchOverviewData(
                        lastOverviewData: lastOverviewData)
                }

                print("Server overview-details data fetched at \(Date())")
            }

            if solarDetailsLastFetchAt == nil
                || Date().timeIntervalSince(solarDetailsLastFetchAt!) > 60 * 30
            {
                print("Fetching solar-details server data...")

                // Preserve the original `try?` semantics: treat any
                // solar-details failure (except timeout) as "no update this
                // tick" rather than a user-visible error.
                let result = try? await withFetchTimeout(
                    CurrentBuildingState.fetchTimeoutSeconds
                ) { [energyManager] in
                    try await energyManager.fetchSolarDetails()
                }
                if let result {
                    solarDetailsData = result
                    solarDetailsLastFetchAt = Date()
                }

                print("Server solar-details data fetched at \(Date())")
            }

            errorMessage = nil
            self.error = nil
        } catch is CancellationError {
            print("⏱ Solar fetch timed out after \(CurrentBuildingState.fetchTimeoutSeconds)s")
            self.error = .fetchTimeout
            errorMessage = "Request timed out."
        } catch {
            self.error = error as? EnergyManagerClientError
            errorMessage = error.localizedDescription
        }
    }
}
