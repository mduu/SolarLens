import SwiftUI

struct MainMenu: View {
    var body: some View {
        HStack {

            VStack {

                Button(
                    action: {},
                    label: {
                        Label("Home", systemImage: "house")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                )
                .buttonStyle(.bordered)
                .foregroundColor(.primary)

                Button(
                    action: {},
                    label: {
                        Label("Settings", systemImage: "gear")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                )
                .buttonStyle(.bordered)
                .foregroundColor(.primary)

                Button(
                    action: {},
                    label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                )
                .buttonStyle(.bordered)
                .foregroundColor(.primary)
                .tint(.red)

                Spacer()

            }
            .padding()
            .frame(maxWidth: 300, maxHeight: .infinity)
            .glassEffect(.regular, in: .rect(cornerRadius: 30.0))

            Spacer()

        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack {
        MainMenu()
    }
    .background(.blue.opacity(0.4).gradient)
}
