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
        BorderBox {
            VStack(alignment: .leading, spacing: 30) {
                Text("Custom Logo")
                    .font(.title3)
                    .fontWeight(.semibold)

                // Preview
                if let logoImage = customLogoImage {
                    VStack(spacing: 16) {
                        Image(uiImage: logoImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
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
                            .frame(width: 70, height: 70)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)

                        Text("No custom logo set")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                Spacer().frame(height: 20)

                // Upload button
                Button(action: { showUploadSheet = true }) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("Upload Logo")
                        Spacer()
                    }
                }
                .foregroundColor(.primary)
                .tint(Color.blue)
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)

                // Delete button
                if customLogoImage != nil {
                    Button(action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove Custom Logo")
                            Spacer()
                        }
                    }
                    .foregroundColor(.primary)
                    .tint(Color.red)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle)
                }

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("ℹ️ Requirements:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("• Max size: 512x512 pixels")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• Max file size: 2MB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• Format: PNG or JPEG")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

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
        .frame(width: 500, height: 500)
}
