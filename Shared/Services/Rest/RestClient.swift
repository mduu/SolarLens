import Combine
import Foundation

class RestClient {
    let baseUrl: String
    private let session: URLSession
    private let jsonEncoder: JSONEncoder = .init()
    private let jsonDecoder: JSONDecoder = .init()

    init(baseUrl: String) {
        self.baseUrl = baseUrl
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:00.000"
        //dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        self.jsonEncoder.dateEncodingStrategy = .formatted(dateFormatter)

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10  // Set timeout to 30 seconds
        session = URLSession(configuration: configuration)
    }

    func get<TResponse>(
        serviceUrl: String,
        parameters: Codable? = nil,
        maxRetry: Int = 4
    )
        async throws
        -> TResponse? where TResponse: Codable
    {
        return try await doRequest(
            serviceUrl: serviceUrl,
            httpMethod: "GET",
            requestBody: NoRequestBody.Instance,
            parameters: parameters,
            useAccessToken: true
        )
    }

    func post<TRequest, TResponse>(
        serviceUrl: String,
        requestBody: TRequest,
        parameters: Codable? = nil,
        useAccessToken: Bool = true
    ) async throws
        -> TResponse? where TRequest: Codable, TResponse: Codable
    {
        return try await doRequest(
            serviceUrl: serviceUrl,
            httpMethod: "POST",
            requestBody: requestBody,
            parameters: parameters,
            useAccessToken: useAccessToken
        )
    }

    func put<TRequest, TResponse>(
        serviceUrl: String,
        requestBody: TRequest,
        parameters: Codable? = nil,
        useAccessToken: Bool = true
    ) async throws
        -> TResponse? where TRequest: Codable, TResponse: Codable
    {
        return try await doRequest(
            serviceUrl: serviceUrl,
            httpMethod: "PUT",
            requestBody: requestBody,
            parameters: parameters,
            useAccessToken: useAccessToken
        )
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
        let delay = UInt64(min(maxDelay, pow(0.5, Double(attempt))))
        print("Request attempt #\(attempt), waiting for \(delay) seconds")
        try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
    }

    private func doRequest<TRequest, TResponse>(
        serviceUrl: String,
        httpMethod: String,
        requestBody: TRequest?,
        parameters: Codable? = nil,
        useAccessToken: Bool = true,
        maxRetry: Int = 4
    ) async throws
        -> TResponse? where TRequest: Codable, TResponse: Codable
    {
        guard let url = URL(string: "\(baseUrl)\(serviceUrl)") else {
            return nil
        }

        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = httpMethod
        if requestBody != nil {
            let body = try! jsonEncoder.encode(requestBody)
            request.httpBody = body

            if let jsonString = String(data: body, encoding: .utf8) {
                debugPrint("httpBody: \(jsonString)")
            } else {
                debugPrint("httpBody: Failed to convert Data to String!")
            }
        }
        if useAccessToken, let accessToken = KeychainHelper.accessToken {
            request.setValue(
                "Bearer " + accessToken,
                forHTTPHeaderField: "Authorization"
            )
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
                let (responseData, responseMeta) = try await session.data(
                    for: request
                )
                data = responseData
                response = responseMeta as? HTTPURLResponse
                print(
                    "HTTP \(httpMethod) done. Status-Code: \(response?.statusCode ?? -1)"
                )

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

            var canRetry = true

            switch response!.statusCode {
            case 200:  // OK with data
                guard data != nil else {
                    throw RestError.invalidResponseNoData(response: response!)
                }

                do {
                    return try jsonDecoder.decode(TResponse.self, from: data!)
                } catch let error {
                    print(
                        "Error deserializing response: \(error.localizedDescription)"
                    )
                    debugPrint(
                        String(data: data!, encoding: .utf8)
                            ?? "Data could not be decoded as UTF-8"
                    )

                    return nil
                }
            case 201, 202, 204:  // OK no data
                return nil
            case 400:  // Bad request
                canRetry = false
                print("ERROR: BAD REQUEST")
                print(
                    "HTTP-Body: \(String(describing: String(data: request.httpBody!, encoding: .utf8)))"
                )
            case 401:  // Unauthorized / Token expired
                canRetry = await handleTokenExpired(
                    failedResponse: response!
                )
            case 403:  // Forbidden
                print("ERROR: FORBIDDEN")
                canRetry = await handleForbidden(
                    failedResponse: response!
                )
            default:
                print(
                    "ERROR HTTP \(httpMethod): \(response!.statusCode), \(String(describing: HTTPURLResponse.localizedString))"
                )
            }

            if canRetry && maxRetry > retryAttempt {
                retryAttempt += 1
            } else {
                print("Request failed after #\(retryAttempt) attempts")
                throw RestError.responseError(response: response!)
            }

        } while true
    }
}
