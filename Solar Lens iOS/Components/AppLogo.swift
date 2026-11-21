import SwiftUI

struct AppLogo: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .center) {
            Image("solarlens")
                .resizable()
                .scaledToFit()
                .cornerRadius(5)
                .frame(maxWidth: 50)

            VStack(alignment: .leading) {

                Text(verbatim: "Solar")
                    .foregroundColor(.accent)
                    .font(.system(size: 24, weight: .bold))

                Text(verbatim: "Lens")
                    .foregroundColor(
                        colorScheme == .light ? .black : .white
                    )
                    .font(.system(size: 24, weight: .bold))

            }
            // A brand name must never break mid-word, even when a narrow
            // screen (e.g. the iPhone Duo's outer display) leaves little room.
            .lineLimit(1)
            .fixedSize()

        }  // :HStack
    }
}

#Preview("Light mode") {
    HStack {
        AppLogo()
            .environment(\.colorScheme, .light)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.white)
}

#Preview("Dark mode") {
    HStack {
        AppLogo()
            .environment(\.colorScheme, .dark)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
}
