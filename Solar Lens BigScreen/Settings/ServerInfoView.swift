import SwiftUI

struct ServerInfoView: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState
    @Environment(\.energyManager) var energyManager
    @State private var serverInfo: ServerInfo?
    @State private var showingLogoutConfirmation = false
    @State private var isLoading = false

    var body: some View {
        BorderBox {
            VStack(alignment: .leading) {
                Text("Server Info")
                    .font(.title3)

                Button(
                    action: {
                        showingLogoutConfirmation = true
                    },
                    label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                )
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                .foregroundColor(.primary)
                .tint(.red)
                .alert(isPresented: $showingLogoutConfirmation) {
                    Alert(
                        title: Text("Confirm Logout"),
                        message: Text("Are you sure you want to log out?"),

                        primaryButton: .destructive(Text("Yes, log out")) {
                            buildings.logout()
                        },

                        // No/Secondary Button (cancels the action)
                        secondaryButton: .cancel(Text("No, Cancel"))
                    )
                }

                if serverInfo != nil {

                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Server Name")
                            Text(serverInfo!.smId)
                        }

                        GridRow {
                            Text("Email")
                            Text(serverInfo!.email)
                        }

                        GridRow {
                            Text("HW Version")
                            Text(serverInfo!.hardwareVersion)
                        }

                        GridRow {
                            Text("SW Version")
                            Text(serverInfo!.softwareVersion)
                        }
                    }

                } else {
                    if isLoading {
                        ProgressView("Loading server info...")
                    } else {
                        ContentUnavailableView(
                            "No server info available.",
                            systemImage: "server.rack",
                            description: Text(
                                "Something went wrong, or the server is not connected."
                            ),
                        )
                    }
                }

            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            isLoading = true
            Task {
                serverInfo = try? await energyManager.fetchServerInfo()
                isLoading = false
            }
        }
    }
}

#Preview {
    ServerInfoView()
}
