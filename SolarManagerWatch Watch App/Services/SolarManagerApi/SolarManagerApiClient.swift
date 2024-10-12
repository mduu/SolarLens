//
//  SolarManagerApi.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 12.10.2024.
//

import Combine
import Foundation

class SolarManagerApi {

    private let apiBaseUrl: String = "https://cloud.solar-manager.ch"

    func login(email: String, password: String) async throws -> LoginResponse? {
        
        // Create HTTP POST request
        let url = URL(string: "\(apiBaseUrl)/v1/oauth/login")!
        let loginRequest = LoginRequest(email: email, password: password)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(loginRequest)
        
        do {
            // POST
            let (data, response) = try await URLSession.shared.data(for: request)
            debugPrint(response)

            // Handle response
            do {
                let loginResponse = try JSONDecoder().decode(
                    LoginResponse.self, from: data)

                return loginResponse
            } catch {
                print("Error decoding login response: \(error)")
                throw SolarManagerApiClientError.errorWhileDecoding
            }
        } catch {
            print(
                "Login failed! Error: \(error). Email: \(email ?? "<no email>"), Passwort: \(password ?? "<no password>")"
            )
            throw SolarManagerApiClientError.communicationError
        }
    }

    func refresh(refreshToken: String) async throws {
        // TODO Refresh
    }
}
