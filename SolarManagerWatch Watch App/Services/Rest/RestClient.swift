//
//  RestClient.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 12.10.2024.
//

import Combine
import Foundation

class RestClient {
    let baseUrl: String

    init(baseUrl: String) {
        self.baseUrl = baseUrl
    }

    func get<TResponse>(serviceUrl: String, parameters: Codable? = nil) async throws
        -> TResponse? where TResponse: Codable
    {
        guard let url = URL(string: "\(baseUrl)\(serviceUrl)") else {
            return nil
        }

        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        if let accessToken = KeychainHelper.accessToken {
            request.setValue(
                "Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request)

            if let response = response as? HTTPURLResponse,
                response.statusCode != 200
            {
                print(
                    "RestClient GET Error: \(response.statusCode), \(String(describing: HTTPURLResponse.localizedString))"
                )
                throw RestError.responseError(response: response)
            }

            print(
                String(data: data, encoding: .utf8)
                    ?? "Data could not be decoded as UTF-8")

            do {
                return try JSONDecoder().decode(TResponse.self, from: data)
            } catch let error {
                print(
                    "Error deserializing response: \(error.localizedDescription)"
                )
                debugPrint(
                    String(data: data, encoding: .utf8)
                        ?? "Data could not be decoded as UTF-8")
                throw error
            }

        } catch let error {
            print("Error while GET request: \(error.localizedDescription)")
            return nil
        }
    }

    func post<TRequest, TResponse>(
        serviceUrl: String, requestBody: TRequest, parameters: Codable? = nil
    ) async throws
        -> TResponse? where TRequest: Codable, TResponse: Codable
    {
        guard let url = URL(string: "\(baseUrl)\(serviceUrl)") else {
            return nil
        }

        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        if let accessToken = KeychainHelper.accessToken {
            request.setValue(
                "Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try! JSONEncoder().encode(requestBody)

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request)

            if let response = response as? HTTPURLResponse,
                response.statusCode != 200
            {
                print(
                    "RestClient POST Error: \(response.statusCode), \(String(describing: HTTPURLResponse.localizedString))"
                )
                throw RestError.responseError(response: response)
            }

            print(
                String(data: data, encoding: .utf8)
                    ?? "Data could not be decoded as UTF-8")

            do {
                return try JSONDecoder().decode(TResponse.self, from: data)
            } catch let error {
                print(
                    "Error deserializing POST response: \(error.localizedDescription)"
                )
                debugPrint(
                    String(data: data, encoding: .utf8)
                        ?? "Data could not be decoded as UTF-8")
                throw error
            }

        } catch let error {
            print("Error while POST request: \(error.localizedDescription)")
            return nil
        }
    }
}
