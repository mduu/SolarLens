import Combine
internal import Foundation

class RestClient {
    let baseUrl: String
    let timeoutForRequest: TimeInterval = 60 // 60 seconds
    let timeoutForResource: TimeInterval = 300 // 5 minutes

    private let session: URLSession
    private let jsonEncoder: JSONEncoder = .init()
    private let jsonDecoder: JSONDecoder = .init()

    init(baseUrl: String) {
        self.baseUrl = baseUrl

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:00.000"
        self.jsonEncoder.dateEncodingStrategy = .formatted(dateFormatter)

        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = timeoutForRequest // Timeout für Request
        configuration.timeoutIntervalForResource = timeoutForResource // Timeout für WaitForConnectivity+Request
        session = URLSession(configuration: configuration)
    }

    func get<TResponse>(
        serviceUrl: String,
        parameters: Encodable? = nil,
        maxRetry: Int = 4
    )
        async throws
        -> TResponse? where TResponse: Decodable
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
        parameters: Encodable? = nil,
        useAccessToken: Bool = true,
        maxRetry: Int = 4
    ) async throws
        -> TResponse? where TRequest: Encodable, TResponse: Decodable
    {
        return try await doRequest(
            serviceUrl: serviceUrl,
            httpMethod: "POST",
            requestBody: requestBody,
            parameters: parameters,
            useAccessToken: useAccessToken,
            maxRetry: maxRetry
        )
    }

    func put<TRequest, TResponse>(
        serviceUrl: String,
        requestBody: TRequest,
        parameters: Encodable? = nil,
        useAccessToken: Bool = true
    ) async throws
        -> TResponse? where TRequest: Encodable, TResponse: Decodable
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
        parameters: Encodable? = nil,
        useAccessToken: Bool = true,
        maxRetry: Int = 4
    ) async throws
        -> TResponse? where TRequest: Encodable, TResponse: Decodable
    {
        guard let url = URL(string: "\(baseUrl)\(serviceUrl)") else {
            return nil
        }

        var request = URLRequest(url: url)
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
                await waitFor(seconds: 2)
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
                    "🟢 HTTP \(httpMethod) \(serviceUrl) -> Status-Code: \(response?.statusCode ?? -1)"
                )

            } catch let error {
                let urlError = error as? URLError
                isTimeout = urlError?.code == .timedOut

                if isTimeout {
                    print("Server request timeout")
                    retryAttempt += 1
                    await waitFor(seconds: 2)
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
                } catch let error as DecodingError {
                    print("🔴📄 Decoding Error: \(error)")

                    switch error {
                        case .keyNotFound(let key, let context):
                            print("--- Key Not Found ---")
                            print("Missing Key: \(key.stringValue)")
                            print("Context: \(context.debugDescription)")

                        case .typeMismatch(let type, let context):
                            print("--- Type Mismatch ---")
                            print("Type Expected: \(type)")
                            print("Context: \(context.debugDescription)")

                        case .valueNotFound(let type, let context):
                            print("--- Value Not Found ---")
                            print("Value of Type \(type) not found.")
                            print("Context: \(context.debugDescription)")

                        case .dataCorrupted(let context):
                            print("--- Data Corrupted ---")
                            print("Context: \(context.debugDescription)")

                        @unknown default:
                            print("An unknown decoding error occurred.")
                    }

                    print("--- Response Content ---")
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
                print("🔴 ERROR: BAD REQUEST (400)")
                print("Debug-Description: \(response.debugDescription)")
                let bodyText =
                    request.httpBody == nil
                    ? ""
                    : "\(String(describing: String(data: request.httpBody!, encoding: .utf8)))"

                print(
                    "HTTP-Body: \(bodyText)"
                )
                
                throw RestError.badRequest(
                    response: response,
                    details: "\(request.httpMethod ?? "-") \(url)\n \(bodyText)")
            case 401:  // Unauthorized / Token expired
                print("🔴🔑 ERROR: FORBIDDEN (403)")
                canRetry = await handleTokenExpired(
                    failedResponse: response!
                )
            case 403:  // Forbidden
                print("🔴🔓 ERROR: FORBIDDEN (403)")
                canRetry = await handleForbidden(
                    failedResponse: response!
                )
            default:
                print(
                    "🔴 ERROR HTTP \(httpMethod): \(response!.statusCode), \(String(describing: HTTPURLResponse.localizedString))"
                )
            }

            if canRetry && maxRetry > retryAttempt {
                retryAttempt += 1
                let millisecondsToWait = UInt64(500 * pow(2, Double(retryAttempt - 1)))
                await waitFor(milliseconds: millisecondsToWait)
            } else {
                print("Request failed after #\(retryAttempt) attempts")
                throw RestError.responseError(response: response!)
            }

        } while true
    }

    private func waitFor(seconds: UInt16) async {
        print("Waiting \(seconds) seconds before retry...")
        try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
    }

    private func waitFor(milliseconds: UInt64) async {
        print("Waiting \(milliseconds) seconds before retry...")
        try? await Task.sleep(nanoseconds: UInt64(milliseconds) * 1_000_000)
    }
}
