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
