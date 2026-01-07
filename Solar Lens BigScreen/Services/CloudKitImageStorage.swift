//
//  CloudKitImageStorage.swift
//  Solar Lens BigScreen
//
//  Manages custom logo and background images in user's private iCloud storage.
//  Images are stored as CKAsset records, syncing across the user's devices.
//

internal import Foundation
import CloudKit
import UIKit

@MainActor
class CloudKitImageStorage {
    static let shared = CloudKitImageStorage()

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    // Record types
    private let customImageRecordType = "CustomImage"

    // Record IDs (fixed IDs so we can update same record)
    private let logoRecordID = CKRecord.ID(recordName: "customLogo")
    private let backgroundRecordID = CKRecord.ID(recordName: "customBackground")

    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
    }

    // MARK: - Save to iCloud

    /// Saves custom logo to user's private iCloud storage
    func saveCustomLogo(_ image: UIImage) async throws {
        try await saveImage(image, recordID: logoRecordID, imageType: "logo")
    }

    /// Saves custom background to user's private iCloud storage
    func saveCustomBackground(_ image: UIImage) async throws {
        try await saveImage(image, recordID: backgroundRecordID, imageType: "background")
    }

    private func saveImage(_ image: UIImage, recordID: CKRecord.ID, imageType: String) async throws {
        // Convert UIImage to PNG data
        guard let imageData = image.pngData() else {
            throw CloudKitImageError.imageConversionFailed
        }

        // Create temporary file for CKAsset
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")

        try imageData.write(to: tempURL)

        // Create or fetch existing record
        let record: CKRecord
        do {
            // Try to fetch existing record to update it
            record = try await privateDatabase.record(for: recordID)
        } catch {
            // Record doesn't exist, create new one
            record = CKRecord(recordType: customImageRecordType, recordID: recordID)
        }

        // Create asset and attach to record
        let asset = CKAsset(fileURL: tempURL)
        record["imageAsset"] = asset
        record["imageType"] = imageType
        record["uploadedAt"] = Date()
        record["deviceID"] = DeviceIdentityManager.shared.deviceID

        // Save to CloudKit
        _ = try await privateDatabase.save(record)

        // Clean up temp file
        try? FileManager.default.removeItem(at: tempURL)

        print("✅ Saved \(imageType) to iCloud")
    }

    // MARK: - Load from iCloud

    /// Loads custom logo from user's private iCloud storage
    func loadCustomLogo() async throws -> UIImage? {
        return try await loadImage(recordID: logoRecordID)
    }

    /// Loads custom background from user's private iCloud storage
    func loadCustomBackground() async throws -> UIImage? {
        return try await loadImage(recordID: backgroundRecordID)
    }

    private func loadImage(recordID: CKRecord.ID) async throws -> UIImage? {
        do {
            let record = try await privateDatabase.record(for: recordID)

            guard let asset = record["imageAsset"] as? CKAsset,
                  let fileURL = asset.fileURL else {
                return nil
            }

            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist yet
            return nil
        }
    }

    // MARK: - Delete from iCloud

    /// Deletes custom logo from user's private iCloud storage
    func deleteCustomLogo() async throws {
        try await deleteImage(recordID: logoRecordID)
    }

    /// Deletes custom background from user's private iCloud storage
    func deleteCustomBackground() async throws {
        try await deleteImage(recordID: backgroundRecordID)
    }

    private func deleteImage(recordID: CKRecord.ID) async throws {
        do {
            _ = try await privateDatabase.deleteRecord(withID: recordID)
            print("✅ Deleted image from iCloud")
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist, nothing to delete
            print("⚠️ Image not found in iCloud (already deleted)")
        }
    }

    // MARK: - Account Status

    /// Checks if user is signed into iCloud
    func checkiCloudStatus() async throws -> Bool {
        let status = try await container.accountStatus()

        switch status {
        case .available:
            return true
        case .noAccount:
            print("⚠️ User not signed into iCloud")
            return false
        case .restricted:
            print("⚠️ iCloud access restricted")
            return false
        case .couldNotDetermine:
            print("⚠️ Could not determine iCloud status")
            return false
        case .temporarilyUnavailable:
            print("⚠️ iCloud temporarily unavailable")
            return false
        @unknown default:
            return false
        }
    }
}

// MARK: - Errors

enum CloudKitImageError: LocalizedError {
    case imageConversionFailed
    case iCloudUnavailable
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to PNG format"
        case .iCloudUnavailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        case .uploadFailed:
            return "Failed to upload image to iCloud"
        }
    }
}
