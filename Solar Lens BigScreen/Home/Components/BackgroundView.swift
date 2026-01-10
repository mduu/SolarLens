import SwiftUI

struct BackgroundView: View {
    @AppStorage("backgroundImageV2") var backgroundImage: String?
    @State private var customBackgroundImage: UIImage?

    private let storageManager = ImageStorageManager.shared

    var body: some View {
        Group {
            if let customBackground = customBackgroundImage {
                Image(uiImage: customBackground)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .backgroundExtensionEffect()
            } else {
                Image(backgroundImage ?? "bg_blue_sunny_clouds_4k")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .backgroundExtensionEffect()
            }
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
        .onReceive(NotificationCenter.default.publisher(for: .customBackgroundDeleted)) { _ in
            Task {
                await MainActor.run {
                    customBackgroundImage = nil
                }
            }
        }
    }

    func loadCustomBackground() async {
        // Try to load from local storage or restore from iCloud if missing
        customBackgroundImage = await storageManager.loadCustomBackground()
    }
}

#Preview {
    BackgroundView()
}
