import SwiftUI
import UIKit

struct ConnectionInfoView: View {
    var serverInfo: ServerInfo?
    var loadFailed: Bool = false
    var onRetry: (() -> Void)? = nil

    @State private var showConfirmation = false

    private var isConnected: Bool { serverInfo?.signal ?? false }

    private var stateColor: Color {
        if serverInfo == nil { return loadFailed ? .red : .gray }
        return isConnected ? .green : .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Solar Manager").font(.headline)

                Spacer()

                if serverInfo != nil {
                    ConnectionStateView(connected: isConnected)
                }
            }

            if serverInfo != nil {
                Grid(alignment: .leading, horizontalSpacing: 20) {
                    GridRow {
                        Text("SM ID:")
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Text(serverInfo?.smId ?? "-")
                            Button {
                                copyToClipboard(text: serverInfo?.smId ?? "")
                                showConfirmation = true
                            } label: {
                                Image(systemName: "document.on.document")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    GridRow {
                        Text("User:")
                            .foregroundStyle(.secondary)
                        Text(serverInfo?.email ?? "-")
                    }
                }
            } else if loadFailed {
                VStack(spacing: 8) {
                    Text("Connection failed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let onRetry {
                        Button("Retry", action: onRetry)
                            .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(stateColor.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
        )
        .alert("Copied!", isPresented: $showConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The SM-ID has been copied to your clipboard.")
        }
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
