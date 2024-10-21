//
//  SolarManagerApi.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 12.10.2024.
//

import Combine
import Foundation

class SolarManagerApi: RestClient {

    private let apiBaseUrl: String = "https://cloud.solar-manager.ch"

    init() {
        super.init(baseUrl: apiBaseUrl)
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        do {
            if let loginResponse: LoginResponse? = try await post(
                serviceUrl: "/v1/oauth/login",
                requestBody: LoginRequest(email: email, password: password),
                useAccessToken: false)
            {
                storeLogin(
                    accessToken: loginResponse!.accessToken,
                    refreshToken: loginResponse!.refreshToken)

                return loginResponse!
            }

            throw SolarManagerApiClientError.communicationError

        } catch {
            clearLogin()

            print(
                "Login failed! Error: \(error). Email: \(email), Passwort: \(password)"
            )
            throw SolarManagerApiClientError.communicationError
        }
    }

    func refresh(refreshToken: String) async throws -> RefreshResponse {
        do {
            if let refreshResponse: RefreshResponse? = try await post(
                serviceUrl: "/v1/oauth/refresh",
                requestBody: RefreshRequest(refreshToken: refreshToken),
                useAccessToken: false)
            {
                storeLogin(
                    accessToken: refreshResponse!.accessToken,
                    refreshToken: refreshResponse!.refreshToken)

                return refreshResponse!
            }

            throw SolarManagerApiClientError.communicationError

        } catch {
            clearLogin()

            print(
                "Refresh failed! Error: \(error)"
            )
            throw SolarManagerApiClientError.communicationError
        }
    }

    func getV1Chart(solarManagerId smId: String) async throws
        -> GetV1ChartResponse?
    {
        let response: GetV1ChartResponse? = try await get(
            serviceUrl: "/v1/chart/gateway/\(smId)")

        return response
    }

    func getV1Users() async throws -> [V1User]? {
        let response: [V1User]? = try await get(
            serviceUrl: "/v1/users")

        return response
    }
    
    func getV1InfoSensors(solarManagerId smId: String) async throws -> [SensorInfosV1Response]? {
        let response: [SensorInfosV1Response]? = try await get(
            serviceUrl: "/v1/info/sensors/\(smId)")
        
        return response
    }
    
    func getV1StreamGateway(solarManagerId smId: String) async throws -> StreamSensorsV1Response? {
        let response: StreamSensorsV1Response? = try await get(
            serviceUrl: "/v1/stream/gateway/\(smId)")
        
        return response
    }

    private func storeLogin(accessToken: String, refreshToken: String) {
        KeychainHelper.accessToken = accessToken
        KeychainHelper.refreshToken = refreshToken
    }

    private func clearLogin() {
        KeychainHelper.accessToken = nil
        KeychainHelper.refreshToken = nil
    }
}
