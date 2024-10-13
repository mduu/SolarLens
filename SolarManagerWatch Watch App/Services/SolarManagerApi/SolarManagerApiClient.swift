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

        // Create HTTP POST request
        let url = URL(string: "\(apiBaseUrl)/v1/oauth/login")!
        let loginRequest = LoginRequest(email: email, password: password)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(loginRequest)

        do {
            // POST
            let (data, response) = try await URLSession.shared.data(
                for: request)
            debugPrint(response)

            // Handle response
            do {
                let loginResponse = try JSONDecoder().decode(
                    LoginResponse.self, from: data)

                KeychainHelper.accessToken = loginResponse.accessToken
                KeychainHelper.refreshToken = loginResponse.refreshToken

                return loginResponse
            } catch {
                print("Error decoding login response: \(error)")
                throw SolarManagerApiClientError.errorWhileDecoding
            }
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

    func getV1Chart(solarManagerId smId: String) async throws -> GetV1ChartResponse? {
        let response: GetV1ChartResponse? = try await get(
            serviceUrl: "/v1/chart/gateway/\(smId)",
            parameters: nil,
            accessToken: KeychainHelper.accessToken)

        return response
    }
}
