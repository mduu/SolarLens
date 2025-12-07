import SwiftUI

struct SettingsScreen: View {
    var closeAction: () -> Void

    var body: some View {

        VStack {
            HStack {

                AppVersionLogo()

                Spacer()

                Text("Settings")
                    .font(.title)
                    .foregroundStyle(.accent)

            }

            HStack {

                VStack {
                    AppearanceConfigurationView()


                    Spacer()
                }
                .frame(maxWidth: .infinity)

                Spacer()

                VStack {
                    ServerInfoView()

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}

#Preview {
    SettingsScreen(
        closeAction: {}
    )
}
