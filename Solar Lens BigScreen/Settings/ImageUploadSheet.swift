import SwiftUI

struct ImageUploadSheet: View {
    let imageType: ImageType
    @Environment(\.dismiss) var dismiss

    @State private var qrCodeImage: UIImage?
    @State private var uploadState: UploadState = .waiting
    @State private var errorMessage: String?

    private let deviceManager = DeviceIdentityManager.shared
    private let imageClient = ImageUploadClient.shared
    private let storageManager = ImageStorageManager.shared

    enum UploadState: Equatable {
        case waiting
        case polling
        case downloading
        case success
        case error(String)

        var message: String {
            switch self {
            case .waiting:
                return "Scan QR code to upload"
            case .polling:
                return "Waiting for upload..."
            case .downloading:
                return "Downloading image..."
            case .success:
                return "Upload successful!"
            case .error(let msg):
                return msg
            }
        }

        var color: Color {
            switch self {
            case .waiting, .polling, .downloading:
                return .white
            case .success:
                return .green
            case .error:
                return .red
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 40) {
                // Title
                Text("Upload custom \(imageType.rawValue)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                if case .success = uploadState {
                    successView
                } else {
                    mainContentView
                }

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Label("Requirements:", systemImage: "info.circle")
                        .fontWeight(.semibold)

                    if imageType == .logo {
                        Text("• Max size: 512x512 pixels")
                            .foregroundColor(.secondary)
                        Text("• Max file size: 2MB")
                            .foregroundColor(.secondary)
                        Text("• Format: PNG or JPEG")
                            .foregroundColor(.secondary)
                    } else {
                        Text("• Max size: 3840x2160 pixels (4K)")
                            .foregroundColor(.secondary)
                        Text("• Max file size: 8MB")
                            .foregroundColor(.secondary)
                        Text("• Format: PNG")
                            .foregroundColor(.secondary)
                    }
                }
                .font(.system(size: 14))
                .padding(.top, 8)

                // Close button
                Button(action: { dismiss() }) {
                    Text(uploadState == .success ? "Done" : "Cancel")
                }
                .padding(.bottom, 40)
            }
            .padding(60)
        }
        .onAppear {
            setupQRCode(imageType: imageType)
            startPolling()
        }
    }

    // MARK: - Subviews

    private var mainContentView: some View {
        VStack(spacing: 40) {
            // QR Code
            if let qrImage = qrCodeImage {
                Image(uiImage: qrImage)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 400, height: 400)
                    .background(Color.white)
                    .cornerRadius(20)
            } else {
                ProgressView()
                    .scaleEffect(2)
                    .frame(width: 400, height: 400)
            }

            // Status
            HStack(spacing: 16) {
                if case .polling = uploadState {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }

                Text(uploadState.message)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(uploadState.color)
            }

            // Instructions
            if case .waiting = uploadState {
                instructionsView
            }
        }
    }

    private var instructionsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                Text("1").stepBubble
                Text("Open camera on your phone").stepText
                Spacer()
            }

            HStack(spacing: 20) {
                Text("2").stepBubble
                Text("Scan the QR code above").stepText
                Spacer()
            }

            HStack(spacing: 20) {
                Text("3").stepBubble
                Text("Select and upload your \(imageType.rawValue.lowercased())").stepText
                Spacer()
            }
        }
        .frame(maxWidth: 800)
    }

    private var successView: some View {
        VStack(spacing: 40) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 120))
                .foregroundColor(.green)

            Text("\(imageType.rawValue) Uploaded Successfully!")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)

            Text("Your custom \(imageType.rawValue.lowercased()) has been saved")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Methods

    private func setupQRCode(imageType: ImageType) {
        let uploadURL = deviceManager.getUploadURL(
            baseURL: ServerUrls.shared.getImageUploadWebBaseUrl(),
            imageType: imageType
        )

        qrCodeImage = QRCodeGenerator.generateWithBackground(from: uploadURL, size: 500)
    }

    private func startPolling() {
        Task {
            uploadState = .polling

            do {
                // Poll for image
                _ = try await imageClient.pollForImage(
                    deviceId: deviceManager.deviceID,
                    imageType: imageType.rawValue
                )

                // Download image
                uploadState = .downloading
                let imageData = try await imageClient.downloadImage(
                    deviceId: deviceManager.deviceID,
                    imageType: imageType.rawValue
                )

                // Save image (local + iCloud backup)
                let savedURL: URL
                if imageType == .logo {
                    savedURL = try await storageManager.saveCustomLogo(data: imageData)
                } else {
                    savedURL = try await storageManager.saveCustomBackground(data: imageData)
                }

                print("✅ Image saved locally and backed up to iCloud: \(savedURL.path)")

                // Post notification
                NotificationCenter.default.post(
                    name: .customImageUploaded,
                    object: nil,
                    userInfo: [
                        "type": imageType.rawValue.lowercased(),
                        "url": savedURL,
                    ]
                )

                // Show success
                await MainActor.run {
                    uploadState = .success
                }

                // Auto-dismiss after 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    dismiss()
                }

            } catch {
                await MainActor.run {
                    uploadState = .error(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - View Extensions

extension Text {
    var stepBubble: some View {
        self
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(Color.blue)
            .clipShape(Circle())
    }

    var stepText: some View {
        self
            .font(.system(size: 20))
            .foregroundColor(.white.opacity(0.9))
    }
}

// MARK: - Notification

extension Notification.Name {
    static let customImageUploaded = Notification.Name("customImageUploaded")
}

// MARK: - Preview

#Preview {
    ImageUploadSheet(imageType: .logo)
}
