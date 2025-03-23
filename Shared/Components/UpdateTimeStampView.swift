import SwiftUI

struct UpdateTimeStampView: View {
    var isStale: Bool
    var updateTimeStamp: Date?
    var isLoading: Bool

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
                
                Text(GetFormattedTimestamp(timestamp: updateTimeStamp))
                    .font(.system(size: 10))
                    .foregroundColor(isStale ? .red : .gray)
                
            }  // :HStack
            .padding(.top, 1)
            
            if isLoading {
                HStack {
                    Image(systemName: "arrow.trianglehead.2.counterclockwise")
                        .symbolEffect(
                            .rotate.byLayer, options: .repeat(.continuous))
                        .font(.system(size: 6))
                        .foregroundColor(.gray)
                        .padding(.leading, 95)
                } // :HStack
            }
        } // :ZStack
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
        isLoading: false)
}

#Preview("Stale") {
    UpdateTimeStampView(
        isStale: true,
        updateTimeStamp: Date(),
        isLoading: false)
}

#Preview("IsLoading") {
    UpdateTimeStampView(
        isStale: false,
        updateTimeStamp: Date(),
        isLoading: true)
}
