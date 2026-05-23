import SwiftUI

/// On-watch viewer + iPhone-export for the rolling activity log
/// produced by `WatchDiagnostics`. Surfaced here because Xcode Organizer
/// and Console.app refuse to show useful data for this app on watchOS —
/// so the file is the only reliable channel.
struct DiagnosticsView: View {
    @State private var content: String = ""
    @State private var showClearConfirm = false
    @State private var exportObserver = DiagnosticsExportState.shared

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
                } label: {
                    Label("Send to iPhone", systemImage: "iphone.gen3")
                }
                .buttonBorderShape(.roundedRectangle)
                .tint(.accent)
                .disabled(exportObserver.status == .sending)

                exportStatusLine

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

    @ViewBuilder
    private var exportStatusLine: some View {
        switch exportObserver.status {
        case .idle:
            EmptyView()
        case .sending:
            Label("Sending to iPhone…", systemImage: "arrow.up.circle")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .sent:
            Label("Sent — open Solar Lens on iPhone → Settings → Activity log from Watch.", systemImage: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.green)
        case .failed(let message):
            Label(
                "Send failed: \(message)",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.caption2)
            .foregroundStyle(.red)
        }
    }
}

/// Observable status of the last "Send to iPhone" export attempt.
/// `AutomationWatchSession` writes here from its WCSession callbacks
/// (via `Task { @MainActor in ... }`); `DiagnosticsView` reads it to
/// surface real feedback after the asynchronous transfer completes.
@MainActor
@Observable
final class DiagnosticsExportState {

    enum Status: Equatable {
        case idle
        case sending
        case sent
        case failed(String)
    }

    static let shared = DiagnosticsExportState()

    var status: Status = .idle

    private init() {}
}

#Preview {
    DiagnosticsView()
}
