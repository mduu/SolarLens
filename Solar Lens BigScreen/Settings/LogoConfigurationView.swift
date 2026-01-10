import SwiftUI

struct LogoConfigurationView: View {
    @State private var showUploadSheet = false
    @State private var customLogoImage: UIImage?
    @State private var showDeleteConfirmation = false

    private let storageManager = ImageStorageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Custom Logo")

            VStack(alignment: .center, spacing: 20) {
                // Preview
                if let logoImage = customLogoImage {
                    VStack(spacing: 12) {
                        Image(uiImage: logoImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 400, height: 120)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)

                        Text("Current custom logo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                            .frame(width: 400, height: 120)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)

                        Text("No custom logo set")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Action buttons
                HStack(spacing: 16) {
                    Button(action: { showUploadSheet = true }) {
                        Label("Upload", systemImage: "qrcode")
                    }
                    .foregroundColor(.primary)

                    if customLogoImage != nil {
                        Button(action: { showDeleteConfirmation = true }) {
                            Label("", systemImage: "trash")
                        }
                        .foregroundColor(.primary)
                        .tint(Color.red)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showUploadSheet) {
            ImageUploadSheet(imageType: .logo)
        }
        .alert("Remove Custom Logo", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                deleteCustomLogo()
            }
        } message: {
            Text("Are you sure you want to remove your custom logo?")
        }
        .task {
            await loadCustomLogo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .customImageUploaded)) { notification in
            if let imageType = notification.userInfo?["type"] as? String, imageType == "logo" {
                Task {
                    await loadCustomLogo()
                }
            }
        }
    }

    private func loadCustomLogo() async {
        // Load from local or restore from iCloud if missing
        customLogoImage = await storageManager.loadCustomLogo()
    }

    private func deleteCustomLogo() {
        Task {
            do {
                // Delete from local and iCloud
                try await storageManager.deleteCustomLogo()
                await MainActor.run {
                    customLogoImage = nil
                }
            } catch {
                print("Error deleting logo: \(error)")
            }
        }
    }
}

#Preview {
    LogoConfigurationView()
        .frame(width: 800, height: 500)
}
