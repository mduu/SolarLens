import SwiftUI

struct PoweredBySolarLens: View {
    var body: some View {
        HStack(spacing: 10) {
            Image("SolarLensLogo")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 40)
                .padding(.all, 0)

            VStack(alignment: .leading) {
                Text("powerd by:")
                    .font(.system(size: 18))
                Text(verbatim: "Solar Lens")
                    .font(.system(size: 22))
            }
        }
    }
}

#Preview {
    PoweredBySolarLens()
}
