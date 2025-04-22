import SwiftUI

struct SettingsScreen: View {
    @Environment(\.energyManager) var energyManager
    @Environment(\.dismiss) var dismiss

    @State private var isLoading = false
    @State private var serverInfo: ServerInfo?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {

                VStack(alignment: .leading) {
                    Text("Solar Lens")
                        .font(.headline)

                    HStack {
                        Text(
                            "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")"
                        )

                        Text(
                            "#\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")"
                        )
                    }

                    ConnectionInfoView(
                        serverInfo: serverInfo
                    )
                    .padding(.vertical)
                }.padding(.horizontal, 16)

                List {

                    Section(header: Text("Settings")) {

                        SettingListItem(
                            imageName: "server.rack",
                            text: "Server Info",
                            color: .purple
                        ) {
                            ServerInfoView(serverInfo: serverInfo)
                        }

                        SettingListItem(
                            imageName: "paintbrush.fill",
                            text: "Apearance",
                            color: .indigo
                        ) {
                        }

                    }
                }
                .selectionDisabled()
                .listStyle(.grouped)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 600)

            }
        }
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
        .padding()
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
