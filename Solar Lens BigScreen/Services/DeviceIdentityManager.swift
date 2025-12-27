//
//  DeviceIdentityManager.swift
//  Solar Lens BigScreen
//
//  Manages unique device identity for image upload
//

internal import Foundation

/// Manages unique device identity for image upload functionality
class DeviceIdentityManager {
    static let shared = DeviceIdentityManager()

    private let userDefaultsKey = "deviceUploadID"
    private var cachedDeviceID: String?

    private init() {}

    /// Get or generate unique device ID
    var deviceID: String {
        // Return cached value if available
        if let cached = cachedDeviceID {
            return cached
        }

        // Try to load from UserDefaults
        if let stored = UserDefaults.standard.string(forKey: userDefaultsKey) {
            cachedDeviceID = stored
            return stored
        }

        // Generate new UUID
        let newID = UUID().uuidString.lowercased()

        // Store in UserDefaults
        UserDefaults.standard.set(newID, forKey: userDefaultsKey)

        // Cache it
        cachedDeviceID = newID

        return newID
    }

    /// Generate upload URL for QR code
    /// - Parameter baseURL: Base URL of the upload website
    /// - Returns: Full URL with device ID parameter
    func getUploadURL(baseURL: String) -> String {
        let cleanURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "\(cleanURL)?device=\(deviceID)"
    }

    /// Reset device ID (for testing only)
    func resetDeviceID() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        cachedDeviceID = nil
    }
}
