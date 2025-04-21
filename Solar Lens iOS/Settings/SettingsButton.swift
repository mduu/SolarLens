import Contacts
import SwiftUI

struct SettingsButton: View {
    @State private var showSettingsSheet = false

    var body: some View {
        RoundIconButton(imageName: "gear") {
            showSettingsSheet = true
        }
        .sheet(isPresented: $showSettingsSheet)
        {
            NavigationView {
                SettingsScreen()
            }
            .presentationDetents([.large])
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
