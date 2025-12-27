//
//  ImageStorageManager.swift
//  Solar Lens BigScreen
//
//  Manages local storage of uploaded images
//

internal import Foundation
import UIKit

/// Manages local storage of custom uploaded images
class ImageStorageManager {
    static let shared = ImageStorageManager()

    private let logoFileName = "custom_logo.png"
    private let backgroundFileName = "custom_background.png"

    private init() {}

    // MARK: - Save

    /// Save custom logo
    func saveCustomLogo(data: Data) throws -> URL {
        try saveImage(data: data, fileName: logoFileName, maxSize: CGSize(width: 512, height: 512))
    }

    /// Save custom background
    func saveCustomBackground(data: Data) throws -> URL {
        try saveImage(data: data, fileName: backgroundFileName, maxSize: CGSize(width: 3840, height: 2160))
    }

    private func saveImage(data: Data, fileName: String, maxSize: CGSize) throws -> URL {
        // Validate image
        guard let image = UIImage(data: data) else {
            throw ImageStorageError.invalidImageFormat
        }

        // Check dimensions
        if image.size.width > maxSize.width || image.size.height > maxSize.height {
            throw ImageStorageError.imageTooLarge
        }

        // Convert to PNG
        guard let pngData = image.pngData() else {
            throw ImageStorageError.conversionFailed
        }

        // Get file URL
        let fileURL = try getFileURL(for: fileName)

        // Write to disk
        try pngData.write(to: fileURL, options: [.atomic])

        print("✅ Saved image to: \(fileURL.path)")

        return fileURL
    }

    // MARK: - Load

    /// Get URL for custom logo
    func getCustomLogoURL() -> URL? {
        getImageURL(for: logoFileName)
    }

    /// Get URL for custom background
    func getCustomBackgroundURL() -> URL? {
        getImageURL(for: backgroundFileName)
    }

    /// Load custom logo as UIImage
    func loadCustomLogo() -> UIImage? {
        guard let url = getCustomLogoURL() else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    /// Load custom background as UIImage
    func loadCustomBackground() -> UIImage? {
        guard let url = getCustomBackgroundURL() else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private func getImageURL(for fileName: String) -> URL? {
        do {
            let url = try getFileURL(for: fileName)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        } catch {
            return nil
        }
    }

    // MARK: - Delete

    /// Delete custom logo
    func deleteCustomLogo() throws {
        try deleteImage(fileName: logoFileName)
    }

    /// Delete custom background
    func deleteCustomBackground() throws {
        try deleteImage(fileName: backgroundFileName)
    }

    private func deleteImage(fileName: String) throws {
        let url = try getFileURL(for: fileName)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
            print("🗑 Deleted image: \(fileName)")
        }
    }

    // MARK: - Helpers

    private func getFileURL(for fileName: String) throws -> URL {
        let documentsDirectory = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return documentsDirectory.appendingPathComponent(fileName)
    }
}

// MARK: - Errors

enum ImageStorageError: LocalizedError {
    case invalidImageFormat
    case imageTooLarge
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .invalidImageFormat:
            return "Invalid image format. Please use PNG or JPEG."
        case .imageTooLarge:
            return "Image exceeds maximum size limits."
        case .conversionFailed:
            return "Failed to process image."
        }
    }
}
