import SwiftUI
import Combine

struct UpdateTimeStampView: View {
    var isStale: Bool
    var updateTimeStamp: Date?
    var isLoading: Bool
    var hasError: Bool = false
    let onRefresh: (() -> Void)?

    @State private var secondsElapsed: TimeInterval = 0
    @State private var isTapped = false
    /// Gates the "Updating" label on a short delay after `isLoading`
    /// flips true. Brief fetches (e.g. when the cache seed is already
    /// fresh, or when watchOS scene-phase flickers fire a redundant
    /// fetch) complete before the delay expires and therefore never
    /// show the label. Only real, slow fetches surface it.
    @State private var showLoadingLabel: Bool = false
    private static let loadingLabelDelay: TimeInterval = 0.6

    var updateTimer = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()

    var body: some View {

        let isRefreshable: Bool = onRefresh != nil

        ZStack {
            HStack {
                ZStack {
                    if isStale {
                        Image(systemName: "exclamationmark.icloud.fill")
                            .foregroundColor(Color.red)
                            .symbolEffect(
                                .pulse.wholeSymbol,
                                options: .repeat(.continuous)
                            )
                            .font(.system(size: 10))
                    }  // :if

                    let hasRealProblem = isStale || hasError
                    // `.secondary` adapts to light/dark mode so the label
                    // stays legible in both. Plain `.gray` is a fixed mid-
                    // gray that's too dim on dark backgrounds.
                    let color: Color = hasRealProblem ? .red : .secondary
                    let secs = secondsElapsed
                    // Only show the red "Old data" label when there is a
                    // genuine persistent issue fetching fresh data (an error
                    // occurred or the server is reporting stale telemetry).
                    // A plain long gap since last fetch (e.g. app was
                    // backgrounded) stays on the regular "Updated …" label
                    // so users don't see a brief red flash on activation.
                    if hasRealProblem && secs >= 300 {
                        Text("Old data")
                            .foregroundColor(showLoadingLabel ? color.opacity(0) : color)
                    } else {
                        let text = secs > 0 ? secs.formatAsHMS() : ""

                        Text("Updated \(text)")
                            .foregroundColor(showLoadingLabel ? color.opacity(0) : color)
                    }

                    if showLoadingLabel {
                        Text("Updating")
                            .foregroundColor(.secondary)
                    }
                }

            }  // :HStack
            .font(.system(size: 10))
            .animation(.easeInOut(duration: 0.2), value: isTapped)
            .padding(.horizontal, isRefreshable ? 6 : 0)
            .padding(.vertical, 1)
            .background(.gray.opacity(isRefreshable ? 0.2 : 0))
            .cornerRadius(5)
            .onTapGesture {
                if !isRefreshable {
                    return
                }

                isTapped.toggle()

                // Reset animation after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isTapped = false
                }

                onRefresh?()
            }
        }  // :ZStack
        .onAppear {
            UpdateSecondsElaped()
        }
        .onReceive(updateTimer) { _ in
            UpdateSecondsElaped()
        }
        .onChange(of: isLoading) { _, newValue in
            if newValue {
                // Only surface the "Updating" label if the fetch is
                // still running after the delay; quick cached fetches
                // (or spurious scene-phase flickers) never make it
                // visible.
                Task { @MainActor in
                    try? await Task.sleep(
                        nanoseconds: UInt64(
                            UpdateTimeStampView.loadingLabelDelay
                                * Double(NSEC_PER_SEC)
                        )
                    )
                    if isLoading {
                        showLoadingLabel = true
                    }
                }
            } else {
                showLoadingLabel = false
            }
        }
    }

    private func UpdateSecondsElaped() {
        guard let updateTimeStamp else {
            secondsElapsed = -1
            return
        }

        secondsElapsed = Date().timeIntervalSince(updateTimeStamp)
    }

    private func GetFormattedTimestamp(timestamp date: Date?) -> String {
        guard let date else { return "-" }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy HH:mm:ss"
        return dateFormatter.string(from: date)
    }
}

#Preview("Normal") {
    UpdateTimeStampView(
        isStale: false,
        updateTimeStamp: Date(),
        isLoading: false,
        onRefresh: {}
    )
}

#Preview("Not refreshable") {
    UpdateTimeStampView(
        isStale: false,
        updateTimeStamp: Date(),
        isLoading: false,
        onRefresh: nil
    )
}

#Preview("Stale") {
    UpdateTimeStampView(
        isStale: true,
        updateTimeStamp: Date(),
        isLoading: false,
        onRefresh: {}
    )
}

#Preview("IsLoading") {
    UpdateTimeStampView(
        isStale: false,
        updateTimeStamp: Date(),
        isLoading: true,
        onRefresh: {}
    )
}
