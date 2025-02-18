import SwiftUI

struct BackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(colorScheme == .light ? .white : .black)
                .ignoresSafeArea()
            
            let backgroundAsset = verticalSizeClass == .compact ? "BackLandscape" : "BackPortrait"
            
            Image(backgroundAsset)
                .resizable()
                .clipped()
                .saturation(0)
                .opacity(colorScheme == .light ? 0.1 : 0.4)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    BackgroundView()
}
