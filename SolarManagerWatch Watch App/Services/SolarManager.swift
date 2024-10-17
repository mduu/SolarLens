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
    private var systemInformation: V1User?

    func fetchOverviewData() async throws -> OverviewData {
        
        try await ensureLoggedIn()
        try await ensureSmId()

        if let chart = try await solarManagerApi.getV1Chart(
            solarManagerId: systemInformation!.sm_id)
        {
            let batteryChargingRate = chart.battery != nil
                ? chart.battery!.batteryCharging - chart.battery!.batteryDischarging
                : nil

            return OverviewData(
                currentSolarProduction: chart.production,
                currentOverallConsumption: chart.consumption,
                currentBatteryLevel: chart.battery?.capacity ?? 0,
                currentBatteryChargeRate: batteryChargingRate,
                currentSolarToGrid: chart
                    .arrows?.first(
                        where: { $0.direction == .fromPVToGrid}
                    )?.value ?? 0,
                currentGridToHouse: chart
                    .arrows?.first(
                        where: { $0.direction == .fromGridToConsumer}
                    )?.value ?? 0,
                currentSolarToHouse: chart
                    .arrows?.first(
                        where: { $0.direction == .fromPVToConsumer}
                    )?.value ?? 0,
                solarProductionMax: (systemInformation?.kWp ?? 0) * 1000)
        } else {
            return OverviewData(
                currentSolarProduction: 0,
                currentOverallConsumption: 0,
                currentBatteryLevel: nil,
                currentBatteryChargeRate: nil,
                currentSolarToGrid: 0,
                currentGridToHouse: 0,
                currentSolarToHouse: 0,
                solarProductionMax: 0)
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
            throw EnergyManagerClientError.loginFailed
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
            KeychainHelper.deleteCredentials()
            throw EnergyManagerClientError.loginFailed
        }
    }

    private func ensureSmId() async throws {
        try await ensureLoggedIn()
        try await ensureSystemInfomation()
    }
    
    private func ensureSystemInfomation() async throws {
        if self.systemInformation != nil {
            return
        }

        print("Requesting System Information ...")

        try await ensureLoggedIn()

        do {
            let users = try await solarManagerApi.getV1Users()
            let firstUser = users?.first
            if firstUser == nil
            {
                throw EnergyManagerClientError.systemInformationNotFound
            }

            self.systemInformation = firstUser
            print("System Informaton loaded. SMID: \(self.systemInformation?.sm_id ?? "<NONE>")")
        }
    }

}
