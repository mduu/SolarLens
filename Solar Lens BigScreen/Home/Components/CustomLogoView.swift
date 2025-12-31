import SwiftUI

/// Displays the custom logo
struct CustomLogoView: View {
    @State private var customLogoImage: UIImage?

    private let storageManager = ImageStorageManager.shared

    var body: some View {
        VStack {
            if let logoImage = customLogoImage {
                Image(uiImage: logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadCustomLogo()
        }
    }

    func loadCustomLogo() {
        customLogoImage = storageManager.loadCustomLogo()
    }
}

#Preview {
    CustomLogoView()
}
