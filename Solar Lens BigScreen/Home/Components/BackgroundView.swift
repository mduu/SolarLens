import SwiftUI

struct BackgroundView: View {
    @AppStorage("backgroundImage") var backgroundImage: String?

    var body: some View {
        Image(backgroundImage ?? "bg_blue_sunny_clouds_4k")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .backgroundExtensionEffect()
    }
}

#Preview {
    BackgroundView()
}
