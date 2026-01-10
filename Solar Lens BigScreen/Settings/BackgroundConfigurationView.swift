import SwiftUI

struct BackgroundConfigurationView: View {
    @State private var showUploadSheet = false
    @State private var customBackgroundImage: UIImage?
    @State private var showDeleteConfirmation = false

    private let storageManager = ImageStorageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Custom Background")

            VStack(alignment: .center, spacing: 20) {
                // Preview
                if let backgroundImage = customBackgroundImage {
                    VStack(spacing: 12) {
                        Image(uiImage: backgroundImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 400, height: 120)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)

                        Text("Current custom background")
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

                        Text("No custom background set")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Action buttons
                VStack(spacing: 16) {
                    Button(action: { showUploadSheet = true }) {
                        Label("Upload", systemImage: "qrcode")
                    }
                    .foregroundColor(.primary)

                    if customBackgroundImage != nil {
                        Button(action: { showDeleteConfirmation = true }) {
                            Label("Remove", systemImage: "trash")
                        }
                        .foregroundColor(.primary)
                        .tint(Color.red)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showUploadSheet) {
            ImageUploadSheet(imageType: .background)
        }
        .alert("Remove Custom Background", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                deleteCustomBackground()
            }
        } message: {
            Text("Are you sure you want to remove your custom background?")
        }
        .task {
            await loadCustomBackground()
        }
        .onReceive(NotificationCenter.default.publisher(for: .customImageUploaded)) { notification in
            if let imageType = notification.userInfo?["type"] as? String, imageType == "background" {
                Task {
                    await loadCustomBackground()
                }
            }
        }
    }

    private func loadCustomBackground() async {
        // Load from local or restore from iCloud if missing
        customBackgroundImage = await storageManager.loadCustomBackground()
    }

    private func deleteCustomBackground() {
        Task {
            do {
                // Delete from local and iCloud
                try await storageManager.deleteCustomBackground()
                await MainActor.run {
                    customBackgroundImage = nil
                }

                // Post notification to update BackgroundView
                NotificationCenter.default.post(
                    name: .customBackgroundDeleted,
                    object: nil
                )
            } catch {
                print("Error deleting background: \(error)")
            }
        }
    }
}

#Preview {
    BackgroundConfigurationView()
        .frame(width: 800, height: 500)
}
