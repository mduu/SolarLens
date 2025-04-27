import SwiftUI

struct SettingsScreen: View {
    @Environment(\.energyManager) var energyManager
    @Environment(\.dismiss) var dismiss

    @State var settings = AppSettings()

    @State private var isLoading = false
    @State private var serverInfo: ServerInfo?

    var body: some View {
        List {

            VStack(alignment: .leading) {
                Text(verbatim: "Solar Lens")
                    .font(.headline)

                HStack {
                    Text(
                        "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")"
                    )

                    Text(
                        "#\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")"
                    )
                }
            }
            .listRowSeparator(.hidden, edges: [.all])
            .padding(.vertical, 0)

            Section(header: Text("Server")) {

                ConnectionInfoView(
                    serverInfo: serverInfo
                )
                .padding(.bottom)
                .listRowSeparator(
                    .hidden,
                    edges: [.all]
                )

                SettingNavigationItem(
                    imageName: "server.rack",
                    text: "Server Info",
                    color: .blue
                ) {
                    ServerInfoView(serverInfo: serverInfo)
                }
                .listRowSeparator(
                    .hidden,
                    edges: [.all]
                )
            }

            Section(header: Text("Appearance")) {

                SettingsToggleItem(
                    imageName: "circle.dotted.circle",
                    text: "Use glow effect",
                    color: .indigo,
                    isOn: settings.appearanceUseGlowEffectWithDefault
                )
            }

        }
        .selectionDisabled()
        .listStyle(.grouped)
        .scrollContentBackground(.hidden)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.indigo)
                }

            }
        }
        .onAppear {
            isLoading = true
            Task {
                defer {
                    isLoading = false
                }

                do {
                    serverInfo = try await energyManager.fetchServerInfo()
                } catch {
                    var _ = Alert(
                        title: Text("Connection error"),
                        message: Text(
                            "Something went wrong! Please try again later."
                        )
                    )
                }
            }
        }
    }

}

#Preview {
    SettingsScreen()
        .environment(CurrentBuildingState.fake())
}
