internal import Foundation
import UIKit

/// Manages local storage of custom uploaded images with iCloud backup
class ImageStorageManager {
    static let shared = ImageStorageManager()

    private let logoFileName = "custom_logo.png"
    private let backgroundFileName = "custom_background.png"

    /// Enable/disable iCloud backup (default: true)
    var iCloudBackupEnabled = true

    private init() {}

    // MARK: - Save

    /// Save custom logo (local + iCloud backup)
    func saveCustomLogo(data: Data) async throws -> URL {
        let url = try saveImageToLocal(data: data, fileName: logoFileName, maxSize: CGSize(width: 512, height: 512))

        // Backup to iCloud asynchronously (non-blocking)
        if iCloudBackupEnabled {
            Task {
                await backupLogoToiCloud(data: data)
            }
        }

        return url
    }

    /// Save custom background (local + iCloud backup)
    func saveCustomBackground(data: Data) async throws -> URL {
        let url = try saveImageToLocal(data: data, fileName: backgroundFileName, maxSize: CGSize(width: 3840, height: 2160))

        // Backup to iCloud asynchronously (non-blocking)
        if iCloudBackupEnabled {
            Task {
                await backupBackgroundToiCloud(data: data)
            }
        }

        return url
    }

    private func saveImageToLocal(data: Data, fileName: String, maxSize: CGSize) throws -> URL {
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

        print("✅ Saved image locally to: \(fileURL.path)")

        return fileURL
    }

    // MARK: - iCloud Backup

    private func backupLogoToiCloud(data: Data) async {
        guard let image = UIImage(data: data) else { return }

        do {
            try await CloudKitImageStorage.shared.saveCustomLogo(image)
        } catch {
            print("⚠️ Failed to backup logo to iCloud: \(error.localizedDescription)")
            // Non-fatal: local save succeeded, iCloud is just a backup
        }
    }

    private func backupBackgroundToiCloud(data: Data) async {
        guard let image = UIImage(data: data) else { return }

        do {
            try await CloudKitImageStorage.shared.saveCustomBackground(image)
        } catch {
            print("⚠️ Failed to backup background to iCloud: \(error.localizedDescription)")
            // Non-fatal: local save succeeded, iCloud is just a backup
        }
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

    /// Load custom logo as UIImage (with iCloud fallback)
    func loadCustomLogo() async -> UIImage? {
        // Try local first
        if let url = getCustomLogoURL() {
            return UIImage(contentsOfFile: url.path)
        }

        // If not found locally, try iCloud restore
        if iCloudBackupEnabled {
            return await restoreLogoFromiCloud()
        }

        return nil
    }

    /// Load custom background as UIImage (with iCloud fallback)
    func loadCustomBackground() async -> UIImage? {
        // Try local first
        if let url = getCustomBackgroundURL() {
            return UIImage(contentsOfFile: url.path)
        }

        // If not found locally, try iCloud restore
        if iCloudBackupEnabled {
            return await restoreBackgroundFromiCloud()
        }

        return nil
    }

    /// Synchronous load (for backwards compatibility, no iCloud fallback)
    func loadCustomLogoSync() -> UIImage? {
        guard let url = getCustomLogoURL() else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    /// Synchronous load (for backwards compatibility, no iCloud fallback)
    func loadCustomBackgroundSync() -> UIImage? {
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

    // MARK: - iCloud Restore

    private func restoreLogoFromiCloud() async -> UIImage? {
        do {
            guard let image = try await CloudKitImageStorage.shared.loadCustomLogo() else {
                return nil
            }

            // Save to local storage for faster future access
            if let pngData = image.pngData() {
                _ = try? saveImageToLocal(data: pngData, fileName: logoFileName, maxSize: CGSize(width: 512, height: 512))
                print("✅ Restored logo from iCloud")
            }

            return image
        } catch {
            print("⚠️ Failed to restore logo from iCloud: \(error.localizedDescription)")
            return nil
        }
    }

    private func restoreBackgroundFromiCloud() async -> UIImage? {
        do {
            guard let image = try await CloudKitImageStorage.shared.loadCustomBackground() else {
                return nil
            }

            // Save to local storage for faster future access
            if let pngData = image.pngData() {
                _ = try? saveImageToLocal(data: pngData, fileName: backgroundFileName, maxSize: CGSize(width: 3840, height: 2160))
                print("✅ Restored background from iCloud")
            }

            return image
        } catch {
            print("⚠️ Failed to restore background from iCloud: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Delete

    /// Delete custom logo (local + iCloud)
    func deleteCustomLogo() async throws {
        try deleteImageLocal(fileName: logoFileName)

        // Also delete from iCloud
        if iCloudBackupEnabled {
            Task {
                do {
                    try await CloudKitImageStorage.shared.deleteCustomLogo()
                } catch {
                    print("⚠️ Failed to delete logo from iCloud: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Delete custom background (local + iCloud)
    func deleteCustomBackground() async throws {
        try deleteImageLocal(fileName: backgroundFileName)

        // Also delete from iCloud
        if iCloudBackupEnabled {
            Task {
                do {
                    try await CloudKitImageStorage.shared.deleteCustomBackground()
                } catch {
                    print("⚠️ Failed to delete background from iCloud: \(error.localizedDescription)")
                }
            }
        }
    }

    private func deleteImageLocal(fileName: String) throws {
        let url = try getFileURL(for: fileName)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
            print("🗑 Deleted local image: \(fileName)")
        }
    }

    // MARK: - Helpers

    private func getFileURL(for fileName: String) throws -> URL {
        let cachesDirectory = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return cachesDirectory.appendingPathComponent(fileName)
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
