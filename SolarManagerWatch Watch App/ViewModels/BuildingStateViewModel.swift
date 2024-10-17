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
    @Published var isDirty: Bool = true
    @Published var errorMessage: String?
    @Published var error: EnergyManagerClientError?
    @Published var loginCredentialsExists: Bool = false
    @Published var overviewData: OverviewData = .init()
    @Published var lastUpdatedAt: Date?

    private let energyManager: EnergyManager

    init(energyManagerClient: EnergyManager = SolarManager()) {
        self.energyManager = energyManagerClient
        self.isDirty = true
        updateCredentialsExists()
    }

    func fetchServerData() async {
        if !loginCredentialsExists || isLoading {
            return
        }

        do {
            isLoading = true
            resetError()

            overviewData = try await energyManager.fetchOverviewData()
            lastUpdatedAt = Date()
            isLoading = false
            isDirty = false
        } catch {
            self.error = error as? EnergyManagerClientError
            errorMessage = error.localizedDescription
            isLoading = false
            isDirty = true
        }
    }

    func login(email: String, password: String) async {
        defer {
            isLoading = false
        }

        resetError()
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
