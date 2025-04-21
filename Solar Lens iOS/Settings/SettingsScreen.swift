import SwiftUI

struct SettingsScreen: View {
    @Environment(\.energyManager) var energyManager
    @Environment(\.dismiss) var dismiss

    @State private var isLoading = false
    @State private var serverInfo: ServerInfo?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                
                Text("Solar Lens")
                    .font(.title)
                
                HStack {
                    Text(
                        "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")"
                    )
                    
                    Text(
                        "#\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")"
                    )
                }
                
                if isLoading {
                    ProgressView()
                        .frame(minWidth: .infinity, maxWidth: 170)
                } else {
                    ConnectionInfoView(
                        serverInfo: serverInfo
                    )
                }

                Spacer()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")  // Use a system icon
                        .resizable()  // Make the image resizable
                        .scaledToFit()  // Fit the image within the available space
                        .frame(width: 18, height: 18)  // Set the size of the image
                        .foregroundColor(.teal)  // Set the color of the image
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
