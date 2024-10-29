//
//  BuildingState.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 29.09.2024.
//

import Foundation

@MainActor
class BuildingStateViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var error: EnergyManagerClientError?
    @Published var loginCredentialsExists: Bool = false
    @Published var didLoginSucceed: Bool? = nil
    @Published var overviewData: OverviewData = .init()
    @Published var isChangingCarCharger: Bool = false
    @Published var carChargerSetSuccessfully: Bool? = nil

    private let energyManager: EnergyManager

    init(energyManagerClient: EnergyManager = SolarManager()) {
        self.energyManager = energyManagerClient
        updateCredentialsExists()
    }

    static func fake(overviewData: OverviewData) -> BuildingStateViewModel {
        let result = BuildingStateViewModel.init(
            energyManagerClient: FakeEnergyManager.init(data: overviewData))
        result.isLoading = false
        result.loginCredentialsExists = true

        Task {
            await result.fetchServerData()
        }

        return result
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
        if !loginCredentialsExists || isLoading {
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

    func setCarCharging() async {
        guard loginCredentialsExists && !isLoading && !isChangingCarCharger
        else {
            return false
        }

        carChargerSetSuccessfully = nil
        isChangingCarCharger = true
        defer {
            isChangingCarCharger = false
        }

        do {

            resetError()

            print("Set car-changing settings \(Date())")

            try await energyManager.setCarChargingMode(
                carCharging: ControlCarChargingRequest)(
                    lastOverviewData: overviewData)

            print("Car-Charging set at \(Date())")

            carChargerSetSuccessfully = true
        } catch {
            carChargerSetSuccessfully = true
        }
    }

    func logout() {
        KeychainHelper.deleteCredentials()
        updateCredentialsExists()
        resetError()
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
