//
//  SolarManagerClient.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//

import Combine
import Foundation


class SolarManagerClient: EnergyManagerClient {
    private let apiBaseUrl: String = "https://cloud.solar-manager.ch/"
    private var accessToken: String?
    private var refreshToken: String?
    private var expireAt: Date?

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
        if let accessToken, let expireAt, expireAt > Date() {
            print("Valid login can be re-used")
            return
        }

        if let refreshToken {
            print("Refresh token exists. Refreshing ...")
            await refresh()
        }

        if let accessToken, let expireAt, expireAt > Date() {
            print("Refresh auth-token succeeded.")
            return
        }

        print("Performe login")
        let loginSuccess = await login()
        if !loginSuccess {
            print("Login failed!")
            throw EnergyManagerClientError.loginFailed("Login failed!")
        } else {
            print("Login succeeded.")
        }
    }

    func refresh() async {
        guard let refreshToken else {
            print("No refresh token available.")
            return
        }
        
        // TODO Refresh
    }

    func login() async -> Bool {
        // Get credentials
        let credentials = KeychainHelper.loadCredentials()
        if (credentials.username?.isEmpty ?? true)
            || (credentials.password?.isEmpty ?? true)
        {
            print("No credentials found!")
            return false
        }

        // Build request content
        guard
            let encodedLoginRequest = try? JSONEncoder().encode(
                LoginRequest(
                    email: credentials.username!,
                    password: credentials.password!))
        else {
            print("Failed to encode login request.")
            return false
        }

        // Create HTTP POST request
        let url = URL(string: "\(apiBaseUrl)/v1/oauth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = encodedLoginRequest

        do {
            let (data, _) = try await URLSession.shared.upload(
                for: request,
                from: encodedLoginRequest)

            // Handle response
            do {
                let loginResponse = try JSONDecoder().decode(
                    LoginResponse.self, from: data)

                self.accessToken = loginResponse.accessToken
                self.refreshToken = loginResponse.refreshToken
                self.expireAt = Date().addingTimeInterval(
                    TimeInterval(loginResponse.expiresIn))

                return true
            } catch {
                print("Error decoding login response: \(error)")
                return false
            }
        } catch {
            print(
                "Login failed! Error: \(error). Email: \(credentials.username ?? "<no email>"), Passwort: \(credentials.password ?? "<no password>")"
            )
            return false
        }
    }
}

class LoginRequest: Codable {
    var email: String
    var password: String

    init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

class LoginResponse: Codable {
    var accessToken: String
    var refreshToken: String
    var expiresIn: Int

    init(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}
