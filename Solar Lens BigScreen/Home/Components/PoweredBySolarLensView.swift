import SwiftUI

struct PoweredBySolarLens: View {
    var body: some View {
        HStack(spacing: 10) {
            Image("SolarLensLogo")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 60)
                .padding(.all, 0)

            VStack(alignment: .leading) {
                Text("powerd by:")
                    .font(.system(size: 24))
                Text(verbatim: "Solar Lens BigScreen")
                    .font(.footnote)
                    .foregroundColor(.accent)
            }
        }
    }
}

#Preview {
    PoweredBySolarLens()
}
