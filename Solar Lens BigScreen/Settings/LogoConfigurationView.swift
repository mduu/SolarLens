//
//  LogoConfigurationView.swift
//  Solar Lens BigScreen
//
//  Logo upload configuration view
//

import SwiftUI

struct LogoConfigurationView: View {
    @State private var showUploadSheet = false
    @State private var customLogoImage: UIImage?
    @State private var showDeleteConfirmation = false

    private let storageManager = ImageStorageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Custom Logo")

            HStack(alignment: .top, spacing: 16) {
                // Preview
                if let logoImage = customLogoImage {
                    VStack(spacing: 16) {
                        Image(uiImage: logoImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 400, height: 100)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)

                        Text("Current custom logo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                            .frame(width: 400, height: 100)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)

                        Text("No custom logo set")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading) {

                    // Upload button
                    Button(action: { showUploadSheet = true }) {
                        Label("Upload Logo", systemImage: "qrcode")
                    }
                    .foregroundColor(.primary)

                    // Delete button
                    if customLogoImage != nil {
                        Button(action: { showDeleteConfirmation = true }) {
                            Label("Remove Logo", systemImage: "trash")
                        }
                        .foregroundColor(.primary)
                        .tint(Color.red)
                    }

                    Spacer()
                }

                Spacer()
            }
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
        .onAppear {
            loadCustomLogo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .customImageUploaded)) { notification in
            if let imageType = notification.userInfo?["type"] as? String, imageType == "logo" {
                loadCustomLogo()
            }
        }
    }

    private func loadCustomLogo() {
        customLogoImage = storageManager.loadCustomLogo()
    }

    private func deleteCustomLogo() {
        do {
            try storageManager.deleteCustomLogo()
            customLogoImage = nil
        } catch {
            print("Error deleting logo: \(error)")
        }
    }
}

#Preview {
    LogoConfigurationView()
        .frame(width: 800, height: 500)
}
