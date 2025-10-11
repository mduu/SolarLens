import SwiftUI
import Combine

struct UpdateTimeStampView: View {
    var isStale: Bool
    var updateTimeStamp: Date?
    var isLoading: Bool
    let onRefresh: (() -> Void)?

    @State private var secondsElapsed: TimeInterval = 0
    @State private var isTapped = false

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

                    let color: Color = isStale ? .red : .gray
                    let secs = secondsElapsed
                    if secs >= 300 {
                        Text("Old data")
                            .foregroundColor(isLoading ? color.opacity(0) : color)
                    } else {
                        let text = secs > 0 ? secs.formatAsHMS() : ""
                        
                        Text("Updated \(text)")
                            .foregroundColor(isLoading ? color.opacity(0) : color)
                    }

                    if isLoading {
                        HStack {
                            Image(
                                systemName: "arrow.trianglehead.2.counterclockwise"
                            )
                            .symbolEffect(
                                .rotate.byLayer,
                                options: .repeat(.continuous)
                            )

                            Text("Updateting")
                        }
                        .foregroundColor(.gray)
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
