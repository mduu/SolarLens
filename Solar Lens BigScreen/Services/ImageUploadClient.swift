internal import Foundation

/// Client for interacting with the image upload Azure Functions
class ImageUploadClient {
    static let shared = ImageUploadClient()

    private let session: URLSession
    private let baseURL: String

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        self.baseURL = ServerUrls.shared.getImageDownloadApiBaseUrl()
    }

    // MARK: - Public API

    /// Check if an image is available for download
    /// - Parameter deviceId: Unique device identifier
    /// - Returns: ImageInfo if available, nil if not
    func checkImageAvailable(deviceId: String, imageType: String) async throws -> ImageCheckResponse? {
        let url = URL(string: "\(baseURL)/check/\(deviceId)/\(imageType)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadClientError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                let imageInfo = try JSONDecoder().decode(ImageCheckResponse.self, from: data)
                return imageInfo
            } catch {
                // Output raw response as plain text for debugging
                if let responseText = String(data: data, encoding: .utf8) {
                    print("❌ JSON decode failed. Raw response:\n\(responseText)")
                } else {
                    print("❌ JSON decode failed. Unable to convert data to string. Data size: \(data.count) bytes")
                }
                throw error
            }
        case 404:
            return nil
        default:
            throw UploadClientError.serverError(httpResponse.statusCode)
        }
    }

    /// Download the image
    /// - Parameter deviceId: Unique device identifier
    /// - Returns: Image data
    func downloadImage(deviceId: String, imageType: String) async throws -> Data {
        let url = URL(string: "\(baseURL)/download/\(deviceId)/\(imageType)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadClientError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw UploadClientError.serverError(httpResponse.statusCode)
        }

        guard !data.isEmpty else {
            throw UploadClientError.emptyResponse
        }

        return data
    }

    /// Poll for image availability with timeout
    /// - Parameters:
    ///   - deviceId: Unique device identifier
    ///   - interval: Polling interval in seconds (default: 2)
    ///   - timeout: Maximum time to poll in seconds (default: 300 = 5 minutes)
    /// - Returns: ImageInfo when available
    func pollForImage(
        deviceId: String,
        imageType: String,
        interval: TimeInterval = 2,
        timeout: TimeInterval = 300
    ) async throws -> ImageCheckResponse {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if let imageInfo = try await checkImageAvailable(deviceId: deviceId, imageType: imageType) {
                if imageInfo.available {
                    return imageInfo
                }
            }

            // Wait before next poll
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }

        throw UploadClientError.timeout
    }
}

// MARK: - Models

struct ImageInfo: Codable {
    let deviceId: String
    let imageType: String // "logo" or "background"
    let sizeBytes: Int
    let uploadedAt: Date

    enum CodingKeys: String, CodingKey {
        case deviceId
        case imageType
        case sizeBytes
        case uploadedAt
    }
}

struct ImageCheckResponse: Codable
{
    let available: Bool

    /// "logo" or "background"
    let imageType: String?

    /// "png" or "jpeg"
    let format: String?
}

// MARK: - Errors

enum UploadClientError: LocalizedError {
    case invalidResponse
    case serverError(Int)
    case emptyResponse
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .emptyResponse:
            return "No image data received"
        case .timeout:
            return "Upload timeout. Please try again."
        }
    }
}
