//
//  BuildingState.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 29.09.2024.
//

import Foundation

enum MainTab: Int, Identifiable {
    case overview
    case charging
    case solarProduction
    
    var id: Int { rawValue }
}

@MainActor
class BuildingStateViewModel: ObservableObject {
    @Published var selectedMainTab = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var error: EnergyManagerClientError?
    @Published var loginCredentialsExists: Bool = false
    @Published var didLoginSucceed: Bool? = nil
    @Published var overviewData: OverviewData = .init()
    @Published var isChangingCarCharger: Bool = false
    @Published var carChargerSetSuccessfully: Bool? = nil
    @Published var fetchingIsPaused: Bool = false
    @Published var chargingInfos: CharingInfoData?

    private let energyManager: EnergyManager

    init(energyManagerClient: EnergyManager = SolarManager.instance) {
        self.energyManager = energyManagerClient
        updateCredentialsExists()
    }

    static func fake(
        overviewData: OverviewData,
        loggedIn: Bool = true,
        isLoading: Bool = false
    ) -> BuildingStateViewModel
    {
        let result = BuildingStateViewModel.init(
            energyManagerClient: FakeEnergyManager.init(data: overviewData))
        result.isLoading = false
        result.loginCredentialsExists = loggedIn

        Task {
            await result.fetchServerData()
        }

        result.isLoading = isLoading

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
            chargingInfos = try await energyManager.fetchChargingData()
            print("Server charging data fetched at \(Date())")

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
        var newTabIdx = 0
        
        switch newTab {
        case .overview: newTabIdx = 0
        case .charging: newTabIdx = 1
        case .solarProduction: newTabIdx = 2
        }
        
        if (selectedMainTab != newTabIdx) {
            selectedMainTab = newTabIdx
        }
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
