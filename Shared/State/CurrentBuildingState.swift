import Foundation
import SwiftUI

@Observable
class CurrentBuildingState {    
    var isLoading = false
    var errorMessage: String?
    var error: EnergyManagerClientError?
    var loginCredentialsExists: Bool = false
    var didLoginSucceed: Bool? = nil
    var overviewData: OverviewData = .init()
    var isChangingCarCharger: Bool = false
    var carChargerSetSuccessfully: Bool? = nil
    var isChangingSensorPriority: Bool = false
    var sensorPrioritySetSuccessfully: Bool? = nil
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

    @MainActor
    func fetchServerData() async {
        if !loginCredentialsExists || isLoading || fetchingIsPaused {
            return
        }

        do {
            withTransaction(Transaction(animation: nil)) {
                isLoading = true
                resetError()
            }

            print("Fetching server data...")

            let newData = try await energyManager.fetchOverviewData(
                lastOverviewData: overviewData)
            
            withTransaction(Transaction(animation: nil)) {
                overviewData = newData;
            }
            
            print("Server data fetched at \(Date())")

            withTransaction(Transaction(animation: nil)) {
                isLoading = false
            }
        } catch {
            self.error = error as? EnergyManagerClientError
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    @MainActor
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

            print("\(Date()): Set sensor \(sensorId) to priority \(newPriority)")

            _ = try await energyManager.setSensorPriority(
                sensorId: sensorId,
                priority: newPriority)

            print("\(Date()): Sensor \(sensorId) priority se to \(newPriority).")

            await fetchServerData()

            sensorPrioritySetSuccessfully = true
            AppStoreReviewManager.shared.setChargingModeSetAtLeastOnce()
        } catch {
            sensorPrioritySetSuccessfully = false
        }
    }

    func logout() {
        KeychainHelper.deleteCredentials()
        updateCredentialsExists()
        resetError()
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
