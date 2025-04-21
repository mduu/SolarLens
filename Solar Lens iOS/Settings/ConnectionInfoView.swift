import SwiftUI
import UIKit

struct ConnectionInfoView: View {
    var serverInfo: ServerInfo?

    @State private var showConfirmation = false

    var body: some View {
        ZStack {
            let borderColor: Color =
                (serverInfo?.signal ?? false) == true
                ? Color.green
                : Color.red

            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(borderColor, lineWidth: 1)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear, borderColor.opacity(0.1),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack {
                HStack {
                    HStack {
                        Text("Solar Manager")
                            .font(.headline)
                    }

                    Spacer()

                    ConnectionStateView(connected: serverInfo?.signal ?? false)
                }

                HStack {
                    Grid(alignment: .leading, horizontalSpacing: 20) {

                        GridRow {
                            Text("SM ID:")
                            Text(serverInfo?.smId ?? "-")
                            Button(action: {
                                copyToClipboard(text: serverInfo?.smId ?? "")
                                showConfirmation = true
                            }) {
                                Image(systemName: "document.on.document")
                                    .foregroundColor(.blue)
                            }
                        }

                        GridRow {
                            Text("User:")
                            Text(serverInfo?.email ?? "-")
                        }
                    }

                    Spacer()
                }
                .padding(.top, 4)
                .alert("Copied!", isPresented: $showConfirmation) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("The SM-ID has been copied to your clipboard.")
                }

                Spacer()

                HStack {
                    Spacer()

                    LogoutButtonView()
                        .disabled(serverInfo == nil || !serverInfo!.signal)

                }

            }.padding()
        }
        .frame(maxHeight: 170)
    }
}

struct ConnectionStateView: View {
    let connected: Bool

    var body: some View {
        HStack {

            if connected {
                Image(systemName: "button.programmable")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        .green,
                        Color.init(rgbString: "#00ff00")!
                    )
                    .symbolEffect(
                        .pulse.byLayer,
                        options: .repeat(.periodic(delay: 2.0))
                    )

                Text("Connected")
            } else {
                Image(systemName: "button.programmable")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        .red,
                        Color.init(rgbString: "#ff0000")!
                    )
                    .symbolEffect(
                        .pulse.byLayer,
                        options: .repeat(.periodic(delay: 2.0))
                    )

                Text("Disconnected")
            }

        }
    }
}

// Helper function to copy a string to the clipboard
func copyToClipboard(text: String) {
    UIPasteboard.general.string = text
}

#Preview("Connected") {
    VStack {
        ConnectionInfoView(
            serverInfo: .fake()
        )
        .padding(20)

        Spacer()
    }
    .environment(CurrentBuildingState.fake())
}

#Preview("No server info") {
    VStack {
        ConnectionInfoView(
            serverInfo: nil
        )
        .padding(20)

        Spacer()
    }
    .environment(CurrentBuildingState.fake())
}
