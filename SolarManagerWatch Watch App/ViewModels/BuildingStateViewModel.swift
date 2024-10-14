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
        if !loginCredentialsExists {
            return
        }

        do {
            isLoading = true
            errorMessage = nil

            overviewData = try await energyManager.fetchOverviewData()
            lastUpdatedAt = Date()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            isDirty = true
        }
    }

    func login(email: String, password: String) {
        defer {
            isLoading = false
        }

        isLoading = true
        KeychainHelper.saveCredentials(username: email, password: password)
        updateCredentialsExists()
    }

    func logout() {
        KeychainHelper.deleteCredentials()
        updateCredentialsExists()
    }

    func updateCredentialsExists() {
        let credentials = KeychainHelper.loadCredentials()

        loginCredentialsExists =
            credentials.username?.isEmpty == false
            && credentials.password?.isEmpty == false
    }
}
