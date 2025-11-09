import SwiftUI

struct SettingsScreen: View {
    var closeAction: () -> Void

    var body: some View {

        VStack {
            Text("Settings View")
                .font(.largeTitle)

            Spacer()

            Button(action: {
                closeAction()
            }, label: {
                Text("Close")
            })
        }
    }
}

#Preview {
    SettingsScreen(
        closeAction: {}
    )
}
