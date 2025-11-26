import SwiftUI

struct SettingsScreen: View {
    var closeAction: () -> Void

    var body: some View {

        VStack {
            Text("Settings View")
                .font(.largeTitle)

            HStack {
                VStack {
                    BackgroundConfiguratonView()
                }
                .frame(minWidth: 600)

                Spacer()
            }

            Spacer()
        }
    }
}

#Preview {
    SettingsScreen(
        closeAction: {}
    )
}
