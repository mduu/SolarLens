//
//  SolarManagerClient.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//

import Combine
import Foundation

actor SolarManager: EnergyManager {
    private var expireAt: Date?
    private var isEnsuringLoggedIn = false
    private var solarManagerApi = SolarManagerApi()
    private var smId: String?

    func fetchOverviewData() async throws -> OverviewData {
        
        try await ensureLoggedIn()
        try await ensureSmId()

        if let chart = try await solarManagerApi.getV1Chart(
            solarManagerId: smId!)
        {
            let networkConsumption = max(
                chart.consumption - chart.production, 0)
            let batteryChargingRate = chart.battery != nil
                ? chart.battery!.batteryCharging - chart.battery!.batteryDischarging
                : nil

            return OverviewData(
                currentSolarProduction: chart.production,
                currentOverallConsumption: chart.consumption,
                currentBatteryLevel: chart.battery?.capacity ?? 0,
                currentNetworkConsumption: networkConsumption,
                currentBatteryChargeRate: batteryChargingRate)
        } else {
            return OverviewData(
                currentSolarProduction: 0,
                currentOverallConsumption: 0,
                currentBatteryLevel: nil,
                currentNetworkConsumption: 0,
                currentBatteryChargeRate: nil)
        }
    }

    private func ensureLoggedIn() async throws {
        if isEnsuringLoggedIn {
            return
        }

        isEnsuringLoggedIn = true
        defer {
            isEnsuringLoggedIn = false
        }

        let accessToken = KeychainHelper.accessToken
        let refreshToken = KeychainHelper.refreshToken

        if accessToken != nil && expireAt != nil && expireAt! > Date() {
            print("Valid login can be re-used")
            return
        }

        if let refreshToken = refreshToken {
            print("Refresh token exists. Refreshing ...")

            do {
                try await solarManagerApi.refresh(refreshToken: refreshToken)
                // TODO Update expire at
                
                if accessToken != nil && expireAt != nil && expireAt! > Date() {
                    print("Refresh auth-token succeeded.")
                    return
                }
            } catch {
            }
        }

        let credentials = KeychainHelper.loadCredentials()
        if (credentials.username?.isEmpty ?? true)
            || (credentials.password?.isEmpty ?? true)
        {
            print("No credentials found!")
            throw EnergyManagerClientError.credentialsMissing
        }

        print("Performe login")

        do {
            let loginSuccess = try await solarManagerApi.login(
                email: credentials.username!,
                password: credentials.password!)

            self.expireAt = Date().addingTimeInterval(
                TimeInterval(loginSuccess.expiresIn))

            print("Login succeeded.")
            return
        } catch {
            KeychainHelper.accessToken = nil
            KeychainHelper.refreshToken = nil
            throw EnergyManagerClientError.loginFailed
        }
    }

    private func ensureSmId() async throws {
        if self.smId != nil {
            return
        }

        print("No SMID found. Requesting ...")

        try await ensureLoggedIn()

        do {
            // TODO Implement this
            //let solarManagerId = try await solarManagerApi.getUser()

            self.smId = "00000000AC513AFE"
        }
    }

}
