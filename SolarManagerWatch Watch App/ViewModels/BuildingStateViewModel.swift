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
    @Published var isLoggedIn: Bool = false
    @Published var overviewData: OverviewData = .init()

    private let energyManager: EnergyManager

    init(energyManagerClient: EnergyManager = SolarManager()) {
        self.energyManager = energyManagerClient
        updateCredentialsExists()
    }

    static func fake(energyManagerClient: EnergyManager)
        -> BuildingStateViewModel
    {
        let result = BuildingStateViewModel.init(
            energyManagerClient: energyManagerClient)

        Task {
            await result.fetchServerData()
        }

        return result
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
            isLoggedIn = true
        } catch {
            self.error = error as? EnergyManagerClientError
            errorMessage = error.localizedDescription
            isLoading = false
            isLoggedIn = self.error != .loginFailed
        }
    }

    func login(email: String, password: String) async {
        defer {
            isLoading = false
        }

        resetError()
        KeychainHelper.accessToken = nil
        KeychainHelper.refreshToken = nil
        KeychainHelper.saveCredentials(username: email, password: password)
        updateCredentialsExists()

        await fetchServerData()
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
