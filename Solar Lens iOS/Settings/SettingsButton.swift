import Contacts
import SwiftUI

struct SettingsButton: View {
    var buttonSize: CGFloat = 48
    @State private var showSettingsSheet = false

    var body: some View {
        RoundIconButton(imageName: "gear", buttonSize: buttonSize) {
            showSettingsSheet = true
        }
        .sheet(isPresented: $showSettingsSheet)
        {
            NavigationStack {
                SettingsScreen()
            }
            .presentationDetents([.large])
            .tint(.indigo)
        }

    }
}

#Preview {
    ZStack {
        BackgroundView()

        VStack {
            HStack {
                SettingsButton()
                    .padding(.top, 40)

                Spacer()
            }

            Spacer()
        }
    }
}
