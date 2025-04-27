import SwiftUI

struct UpdateTimeStampView: View {
    var isStale: Bool
    var updateTimeStamp: Date?
    var isLoading: Bool

    @State private var secondsElapsed: TimeInterval = 0

    var updateTimer = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        ZStack {
            HStack {
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
                let text = secs >= 0 ? secs.formatAsHMS() : ""

                Text("Updated \(text)")
                    .font(.system(size: 10))
                    .foregroundColor(color)

            }  // :HStack
            .padding(.top, 1)

            if isLoading {
                HStack {
                    Image(systemName: "arrow.trianglehead.2.counterclockwise")
                        .symbolEffect(
                            .rotate.byLayer,
                            options: .repeat(.continuous)
                        )
                        .font(.system(size: 6))
                        .foregroundColor(.gray)
                        .padding(.leading, 95)
                }  // :HStack
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
        isLoading: false
    )
}

#Preview("Stale") {
    UpdateTimeStampView(
        isStale: true,
        updateTimeStamp: Date(),
        isLoading: false
    )
}

#Preview("IsLoading") {
    UpdateTimeStampView(
        isStale: false,
        updateTimeStamp: Date(),
        isLoading: true
    )
}
