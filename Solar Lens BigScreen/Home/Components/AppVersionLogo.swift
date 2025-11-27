import SwiftUI

struct AppVersionLogo: View {
    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image("SolarLensLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 55, height: 55)
                .cornerRadius(13)
                .padding(.trailing, 5)

            VStack(alignment: .leading) {
                Text(verbatim: "Solar Lens")

                HStack(spacing: 0) {

                    Text(
                        verbatim:
                            "v \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")"
                    )

                    Text(
                        verbatim: ".\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")"
                    )

                }  // :HStack
                .font(.system(size: 18))

            }

        }
        .padding(.bottom, 2)
    }
}

#Preview {
    AppVersionLogo()
}
