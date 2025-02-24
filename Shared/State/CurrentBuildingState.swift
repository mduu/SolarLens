import Foundation
import SwiftUI

@Observable
class CurrentBuildingState {    
    var selectedMainTab: MainTab = .overview
    var isLoading = false
    var errorMessage: String?
    var error: EnergyManagerClientError?
    var loginCredentialsExists: Bool = false
    var didLoginSucceed: Bool? = nil
    var overviewData: OverviewData = .init()
    var isChangingCarCharger: Bool = false
    var carChargerSetSuccessfully: Bool? = nil
    var fetchingIsPaused: Bool = false
    var chargingInfos: CharingInfoData?

    private let energyManager: EnergyManager

    init(energyManagerClient: EnergyManager) {
        self.energyManager = energyManagerClient
        updateCredentialsExists()
    }
    
    init() {
        self.energyManager = SolarManager.instance()
        updateCredentialsExists()
    }

    static func fake(
        overviewData: OverviewData = OverviewData.fake(),
        loggedIn: Bool = true,
        isLoading: Bool = false,
        didLoginSucceed: Bool? = nil
    ) -> CurrentBuildingState
    {
        let result = CurrentBuildingState.init(
            energyManagerClient: FakeEnergyManager.init(data: overviewData))
        result.isLoading = false
        result.loginCredentialsExists = loggedIn

        Task {
            await result.fetchServerData()
        }

        result.isLoading = isLoading
        result.didLoginSucceed = didLoginSucceed

        return result
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
            username: email, password: password)
        updateCredentialsExists()

        if didLoginSucceed == true {
            resetError()
        }
    }

    func fetchServerData() async {
        if !loginCredentialsExists || isLoading || fetchingIsPaused {
            return
        }

        do {
            isLoading = true
            resetError()

            print("Fetching server data...")

            overviewData = try await energyManager.fetchOverviewData(
                lastOverviewData: overviewData)
            print("Server data fetched at \(Date())")

            isLoading = false
        } catch {
            self.error = error as? EnergyManagerClientError
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func fetchChargingInfos() async {
        if !loginCredentialsExists || isLoading {
            return
        }

        do {
            print("\(Date()) - Fetching charing data")
            chargingInfos = try await energyManager.fetchChargingData()
            print("\(Date()) - Server charging data fetched")

            isLoading = false
        } catch {
            self.error = error as? EnergyManagerClientError
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

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
                carCharging: newCarCharging)

            print("Car-Charging set at \(Date())")

            // Optimistic UI: Update charging mode in-memory to speed up UI
            let chargingStation = overviewData.chargingStations
                .first(where: { $0.id == sensorId })
            chargingStation?.chargingMode = newCarCharging.chargingMode

            carChargerSetSuccessfully = result
            AppStoreReviewManager.shared.setChargingModeSetAtLeastOnce()
        } catch {
            carChargerSetSuccessfully = false
        }
    }

    func logout() {
        KeychainHelper.deleteCredentials()
        updateCredentialsExists()
        resetError()
    }
    
    func setMainTab(newTab: MainTab) {
        if selectedMainTab != newTab {
            selectedMainTab = newTab
        }
    }
    
    func checkForCredentions() {
        updateCredentialsExists()
    }
    
    private func updateCredentialsExists() {
        let credentials = KeychainHelper.loadCredentials()

        loginCredentialsExists =
            credentials.username?.isEmpty == false
            && credentials.password?.isEmpty == false
    }

    private func resetError() {
        errorMessage = nil
        error = nil
    }
}

enum MainTab: Int, CaseIterable, Identifiable {
    case overview = 0
    case charging = 1
    case solarProduction = 2
    
    var id: Self { self }
}
