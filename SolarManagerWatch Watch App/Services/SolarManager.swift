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
    private var accessClaims: [String]?
    private var solarManagerApi = SolarManagerApi()
    private var systemInformation: V1User?
    private var sensorInfos: [SensorInfosV1Response]?
    private var sensorInfosUpdatedAt: Date?

    func login(username: String, password: String) async -> Bool {
        return await doLogin(email: username, password: password)
    }

    func fetchOverviewData(lastOverviewData: OverviewData?) async throws
        -> OverviewData
    {
        try await ensureLoggedIn()
        try await ensureSmId()
        try await ensureSensorInfosAreCurrent()

        // GET chart:SSID
        if let chart = try await solarManagerApi.getV1Chart(
            solarManagerId: systemInformation!.sm_id)
        {
            let batteryChargingRate =
                chart.battery != nil
                ? chart.battery!.batteryCharging
                    - chart.battery!.batteryDischarging
                : nil

            // GET stream/gateway/:SSID
            let streamSensorInfos =
                try await solarManagerApi.getV1StreamGateway(
                    solarManagerId: systemInformation!.sm_id)

            let isAnyCarCharing = getIsAnyCarCharing(
                streamSensors: streamSensorInfos)

            return OverviewData(
                currentSolarProduction: chart.production,
                currentOverallConsumption: chart.consumption,
                currentBatteryLevel: chart.battery?.capacity ?? 0,
                currentBatteryChargeRate: batteryChargingRate,
                currentSolarToGrid: chart
                    .arrows?.first(
                        where: { $0.direction == .fromPVToGrid }
                    )?.value ?? 0,
                currentGridToHouse: chart
                    .arrows?.first(
                        where: { $0.direction == .fromGridToConsumer }
                    )?.value ?? 0,
                currentSolarToHouse: chart
                    .arrows?.first(
                        where: { $0.direction == .fromPVToConsumer }
                    )?.value ?? 0,
                solarProductionMax: (systemInformation?.kWp ?? 0.0) * 1000,
                hasConnectionError: false,
                lastUpdated: Date(),
                isAnyCarCharing: isAnyCarCharing,
                chargingStations: sensorInfos == nil
                    ? []
                    : sensorInfos!
                        .filter { $0.isCarCharging() }
                        .map {
                            let id = $0._id
                            let streamInfo = streamSensorInfos?.devices.first {
                                $0._id == id
                            }

                            return ChargingStation.init(
                                id: $0._id,
                                name: $0.device_group,
                                chargingMode: streamInfo?.currentMode
                                    ?? ChargingMode.off,
                                priority: $0.priority,
                                currentPower: streamInfo?.currentPower ?? 0,
                                signal: $0.signal)
                        })
        }

        var errorOverviewData =
            lastOverviewData
            ?? OverviewData(
                currentSolarProduction: 0,
                currentOverallConsumption: 0,
                currentBatteryLevel: nil,
                currentBatteryChargeRate: nil,
                currentSolarToGrid: 0,
                currentGridToHouse: 0,
                currentSolarToHouse: 0,
                solarProductionMax: 0,
                hasConnectionError: true,
                lastUpdated: Date(),
                isAnyCarCharing: false,
                chargingStations: [])

        errorOverviewData.hasConnectionError = true

        return errorOverviewData
    }

    func setCarChargingMode(
        sensorId: String,
        carCharging: ControlCarChargingRequest
    ) async throws
        -> Bool
    {
        try await ensureLoggedIn()
        try await ensureSmId()
        try await ensureSensorInfosAreCurrent()

        do {
            try await solarManagerApi.putControlCarCharger(
                sensorId: sensorId,
                control: carCharging)
            return true
        } catch {
            return false
        }
    }

    private func ensureLoggedIn() async throws {
        let accessToken = KeychainHelper.accessToken
        let refreshToken = KeychainHelper.refreshToken

        if accessToken != nil && expireAt != nil && expireAt! > Date() {
            return
        }

        if let refreshToken = refreshToken {
            print("Refresh token exists. Refreshing access-token...")

            do {
                let refreshResponse = try await solarManagerApi.refresh(
                    refreshToken: refreshToken)

                self.expireAt = Date().addingTimeInterval(
                    TimeInterval(refreshResponse.expiresIn))
                self.accessClaims = refreshResponse.accessClaims

                if accessToken != nil && expireAt != nil && expireAt! > Date() {
                    print(
                        "Refresh auth-token succeeded. Token will expire at \(expireAt!)"
                    )

                    return
                }

                print("Refresh access-token succeeded.")
            } catch {
                print(
                    "Refresh access-token failed. Will performan a regular login."
                )
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

        let loginSuccess = await doLogin(
            email: credentials.username!,
            password: credentials.password!)

        if !loginSuccess {
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

        let users = try await solarManagerApi.getV1Users()
        let firstUser = users?.first
        if firstUser == nil {
            throw EnergyManagerClientError.systemInformationNotFound
        }

        self.systemInformation = firstUser
        print(
            "System Informaton loaded. SMID: \(self.systemInformation?.sm_id ?? "<NONE>")"
        )
    }

    private func ensureSensorInfosAreCurrent() async throws {
        try await ensureLoggedIn()
        try await ensureSmId()

        if sensorInfos != nil && sensorInfosUpdatedAt != nil
            && Date.now < sensorInfosUpdatedAt!.addingTimeInterval(60)
        {
            print("Reuse existing sensor infos")
        }

        sensorInfos = try await solarManagerApi.getV1InfoSensors(
            solarManagerId: systemInformation!.sm_id)
    }

    private func getIsAnyCarCharing(streamSensors: StreamSensorsV1Response?)
        -> Bool
    {
        guard streamSensors != nil else { return false }
        guard sensorInfos != nil else { return false }

        let chargingSensorIds =
            sensorInfos!.filter {
                $0.type == "Car Charging" && $0.device_type == "device"
            }
            .map { $0._id }

        let charingPower = streamSensors!.devices
            .filter { chargingSensorIds.contains($0._id) }
            .map { $0.currentPower ?? 0 }
            .reduce(0, +)

        return charingPower > 0
    }

    private func doLogin(email: String, password: String) async -> Bool {
        do {
            let loginSuccess = try await solarManagerApi.login(
                email: email,
                password: password)

            KeychainHelper.saveCredentials(username: email, password: password)
            self.expireAt = Date().addingTimeInterval(
                TimeInterval(loginSuccess.expiresIn))
            self.systemInformation = nil

            print("Login succeeded. Token will expire at \(expireAt!)")

            return true
        } catch {
            print("Login failed!")
            return false
        }
    }

}
