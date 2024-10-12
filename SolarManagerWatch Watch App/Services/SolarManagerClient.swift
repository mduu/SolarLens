//
//  SolarManagerClient.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//

import Combine
import Foundation

class SolarManagerClient: EnergyManagerClient {
    private var accessToken: String?
    private var refreshToken: String?
    private var expireAt: Date?
    private var isEnsuringLoggedIn = false
    private var solarManagerApi = SolarManagerApi()

    func fetchOverviewData() async throws -> OverviewData {
        try await ensureLoggedIn()

        return OverviewData(
            currentSolarProduction: 3.2,
            currentOverallConsumption: 0.8,
            currentBatteryLevel: 42,
            currentNetworkConsumption: 0.01,
            currentBatteryChargeRate: 2.4)
    }

    func ensureLoggedIn() async throws {
        if isEnsuringLoggedIn {
            return
        }

        isEnsuringLoggedIn = true
        defer {
            isEnsuringLoggedIn = false
        }

        if let accessToken, let expireAt, expireAt > Date() {
            print("Valid login can be re-used")
            return
        }

        if let refreshToken {
            print("Refresh token exists. Refreshing ...")
            try await solarManagerApi.refresh(refreshToken: self.refreshToken!)
        }

        if let accessToken, let expireAt, expireAt > Date() {
            print("Refresh auth-token succeeded.")
            return
        }

        let credentials = KeychainHelper.loadCredentials()
        if (credentials.username?.isEmpty ?? true)
            || (credentials.password?.isEmpty ?? true)
        {
            print("No credentials found!")
            return
        }

        print("Performe login")
        let loginSuccess = try await solarManagerApi.login(
            email: credentials.username!,
            password: credentials.password!)
        
        if loginSuccess == nil {
            print("Login failed!")
            throw EnergyManagerClientError.loginFailed("Login failed!")
        } else {

            self.accessToken = loginSuccess?.accessToken
            self.refreshToken = loginSuccess?.refreshToken
            self.expireAt = Date().addingTimeInterval(
                TimeInterval(loginSuccess?.expiresIn ?? 0))

            print("Login succeeded.")
        }

    }

}
