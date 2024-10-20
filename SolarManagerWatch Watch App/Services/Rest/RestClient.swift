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
    private let session: URLSession

    init(baseUrl: String) {
        self.baseUrl = baseUrl

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10  // Set timeout to 30 seconds
        session = URLSession(configuration: configuration)
    }

    func get<TResponse>(
        serviceUrl: String, parameters: Codable? = nil, maxRetry: Int = 3
    )
        async throws
        -> TResponse? where TResponse: Codable
    {
        guard let url = URL(string: "\(baseUrl)\(serviceUrl)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        if let accessToken = KeychainHelper.accessToken {
            request.setValue(
                "Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }

        var retryAttempt = 0

        repeat {

            if retryAttempt > 0 {
                await exponentialWait(attempt: retryAttempt)
                print("Retrying request...")
            }
            
            var isTimeout = false
            var data: Data?
            var response: HTTPURLResponse?

            do {
                let (responseData, responseMeta) = try await session.data(for: request)
                data = responseData
                response = responseMeta as? HTTPURLResponse
                
            } catch let error {
                let urlError = error as? URLError
                isTimeout = urlError?.code == .timedOut
                
                if isTimeout {
                    print("Server request timeout")
                    retryAttempt += 1
                    continue
                } else {
                    throw error
                }
            }
            
            if response?.statusCode == 200 && data != nil {
                do {
                    return try JSONDecoder().decode(TResponse.self, from: data!)
                } catch let error {
                    print(
                        "Error deserializing response: \(error.localizedDescription)"
                    )
                    debugPrint(
                        String(data: data!, encoding: .utf8)
                            ?? "Data could not be decoded as UTF-8")

                    return nil
                }
            } else if (response != nil) {
                var canRetry = true

                switch response!.statusCode {
                case 401:  // Unauthorized / Token expired
                    canRetry = await handleTokenExpired(
                        failedResponse: response!)
                case 403:  // Forbidden
                    canRetry = await handleForbidden(
                        failedResponse: response!)
                default:
                    print(
                        "RestClient GET Error: \(response!.statusCode), \(String(describing: HTTPURLResponse.localizedString))"
                    )
                }

                if canRetry && maxRetry > retryAttempt {
                    retryAttempt += 1
                } else {
                    print("Request failed after #\(retryAttempt) attempts")
                    throw RestError.responseError(response: response!)
                }
            }

        } while true
    }

    func post<TRequest, TResponse>(
        serviceUrl: String,
        requestBody: TRequest,
        parameters: Codable? = nil,
        useAccessToken: Bool = true
    ) async throws
        -> TResponse? where TRequest: Codable, TResponse: Codable
    {
        guard let url = URL(string: "\(baseUrl)\(serviceUrl)") else {
            return nil
        }

        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(requestBody)

        do {
            if useAccessToken, let accessToken = KeychainHelper.accessToken {
                request.setValue(
                    "Bearer " + accessToken, forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await session.data(
                for: request)

            if let response = response as? HTTPURLResponse,
                response.statusCode != 200, response.statusCode != 201
            {
                print(
                    "RestClient POST Error: \(response.statusCode), \(String(describing: HTTPURLResponse.localizedString))"
                )
                throw RestError.responseError(response: response)
            }

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

    internal func handleTokenExpired(failedResponse: HTTPURLResponse) async
        -> Bool
    {
        return false
    }

    internal func handleForbidden(failedResponse: HTTPURLResponse) async -> Bool
    {
        return false
    }

    private func exponentialWait(attempt: Int, maxDelay: Double = 20.0) async {
        let delay = UInt64(min(maxDelay, pow(2.0, Double(attempt))))
        print("Request attempt #\(attempt), waiting for \(delay) seconds")
        try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
    }
}
