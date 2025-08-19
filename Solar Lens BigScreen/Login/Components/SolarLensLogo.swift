import SwiftUI

struct SolarLensLogo: View {
    var body: some View {
        Image("App Icon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 150, height: 150)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding()
    }
}

#Preview {
    SolarLensLogo()
}
