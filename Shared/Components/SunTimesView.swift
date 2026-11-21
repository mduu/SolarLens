import SwiftUI

struct SunTimesView: View {
    var sunrise: Date?
    var sunset: Date?

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        // Side by side when there is room; stacked on narrow cards (e.g. the
        // iPhone Duo's outer display), so a time never breaks across lines.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) { times }
            VStack(alignment: .leading, spacing: 4) { times }
        }
        .padding(.vertical, 4)
        .padding(.top, 0)
    }

    @ViewBuilder
    private var times: some View {
        if let sunrise {
            sunTime(systemImage: "sunrise.fill", date: sunrise)
        }

        if let sunset {
            sunTime(systemImage: "sunset.fill", date: sunset)
        }
    }

    private func sunTime(systemImage: String, date: Date) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.multicolor)
            Text(timeFormatter.string(from: date))
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .fixedSize()
    }
}

#Preview {
    SunTimesView(sunrise: Date(), sunset: Date())
}
