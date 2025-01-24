import SwiftUI

struct BackgroundView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(colorScheme == .light ? .white : .black)
                .ignoresSafeArea()
            
            Image("OverviewFull")
                .resizable()
                .clipped()
                .saturation(0)
                .opacity(colorScheme == .light ? 0.1 : 0.4)
                .ignoresSafeArea()
        }
    }
}
