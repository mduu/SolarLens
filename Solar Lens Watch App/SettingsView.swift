import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: BuildingStateViewModel
    @State private var showConfirmation = false
    @State private var showRateApp = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {

                Text("Settings")
                    .font(.headline)
                    .foregroundColor(.accent)

                Divider()

                Text("Logged in as:")
                    .font(.caption)
                Text(
                    "\(KeychainHelper.loadCredentials().username ?? "-")"
                )
                .foregroundColor(.accent)
                .minimumScaleFactor(0.3)

                Button("Log out", systemImage: "iphone.and.arrow.right.outward")
                {
                    showConfirmation = true
                }.labelStyle(.titleAndIcon)
                    .buttonBorderShape(.roundedRectangle)
                    .foregroundColor(.accentColor)
                    .confirmationDialog(
                        "Are you sure to log out?",
                        isPresented: $showConfirmation
                    ) {
                        Button("Confirm") {
                            model.logout()
                        }
                        Button("Cancel", role: .cancel) {}
                    }

                Divider()

                Text("Version:")
                    .font(.caption)

                HStack {
                    Text(
                        "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")"
                    )

                    Text(
                        "#\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")"
                    )
                }  // :HStack
                .font(.caption)
                .foregroundColor(.accent)

                Button("Rate app", systemImage: "star.leadinghalf.filled") {
                    showRateApp = true
                }.labelStyle(.titleAndIcon)
                    .buttonBorderShape(.roundedRectangle)
                    .foregroundColor(.accent)
                    .sheet(isPresented: $showRateApp) {
                        AppReviewRequestView()
                    }
            }  // :VStack
        }  // :ScrollView
    }  // :View
}

#Preview("English") {
    SettingsView()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            ))
}

#Preview("German") {

    SettingsView()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            )
        )
        .environment(\.locale, Locale(identifier: "DE"))
}

#Preview("French") {

    SettingsView()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            )
        )
        .environment(\.locale, Locale(identifier: "FR"))
}

#Preview("Italian") {

    SettingsView()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            )
        )
        .environment(\.locale, Locale(identifier: "IT"))
}
