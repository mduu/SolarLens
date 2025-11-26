import SwiftUI

struct SettingsScreen: View {
    var closeAction: () -> Void

    var body: some View {

        VStack {
            Text("Settings")
                .font(.largeTitle)
                .padding(.bottom, 30)

            HStack {
                VStack {
                    BackgroundConfiguratonView()
                        .frame(minWidth: 800)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
    }
}

#Preview {
    SettingsScreen(
        closeAction: {}
    )
}
