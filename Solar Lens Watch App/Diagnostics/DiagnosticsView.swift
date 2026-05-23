import SwiftUI

/// On-watch viewer + iPhone-export for the rolling activity log
/// produced by `WatchDiagnostics`. Surfaced here because Xcode Organizer
/// and Console.app refuse to show useful data for this app on watchOS —
/// so the file is the only reliable channel.
struct DiagnosticsView: View {
    @State private var content: String = ""
    @State private var showClearConfirm = false
    @State private var exportFeedback: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text(
                    "Activity that stays on this watch unless you tap “Send to iPhone”. Used to diagnose issues."
                )
                .font(.caption2)
                .foregroundStyle(.secondary)

                Divider()

                if content.isEmpty {
                    Text(
                        "Log is empty. Lifecycle events appear immediately; heartbeat fires once per minute while the app is in front."
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                } else {
                    Text(content)
                        .font(.system(size: 9, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                Button {
                    AutomationWatchSession.shared.exportLogToPhone()
                    exportFeedback = String(
                        localized: "Sending to iPhone…"
                    )
                } label: {
                    Label("Send to iPhone", systemImage: "iphone.gen3")
                }
                .buttonBorderShape(.roundedRectangle)
                .tint(.accent)

                if let exportFeedback {
                    Text(exportFeedback)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Label("Clear log", systemImage: "trash")
                }
                .buttonBorderShape(.roundedRectangle)
                .confirmationDialog(
                    "Clear activity log?",
                    isPresented: $showClearConfirm
                ) {
                    Button("Clear", role: .destructive) {
                        WatchDiagnostics.shared.clear()
                        content = ""
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Activity log")
        .onAppear {
            content = WatchDiagnostics.shared.readAll()
        }
    }
}

#Preview {
    DiagnosticsView()
}
