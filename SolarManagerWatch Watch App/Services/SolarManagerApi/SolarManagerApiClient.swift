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
                requestBody: LoginRequest(email: email, password: password))
            {
                KeychainHelper.accessToken = loginResponse!.accessToken
                KeychainHelper.refreshToken = loginResponse!.refreshToken

                return loginResponse!
            }

            throw SolarManagerApiClientError.communicationError

        } catch {
            KeychainHelper.accessToken = nil
            KeychainHelper.refreshToken = nil

            print(
                "Login failed! Error: \(error). Email: \(email), Passwort: \(password)"
            )
            throw SolarManagerApiClientError.communicationError
        }
    }

    func refresh(refreshToken: String) async throws {
        // TODO Refresh
        // TODO Store new accessToken
        // TODO Return new expiresAt
        print("NOT IMPLEMENTED YET - Refresh access token !!!")
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
}
