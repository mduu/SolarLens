import SwiftUI

struct DayForecastView: View {
    var dayForecast: ForecastItem?
    var dayLabel: String
    var overallMinimum: Double
    var overallMaximum: Double

    private var hasData: Bool {
        dayForecast != nil
    }

    private var minVal: Double {
        guard let f = dayForecast else { return 0 }
        return f.min
    }

    private var maxVal: Double {
        guard let f = dayForecast else { return 0 }
        return f.max
    }

    private var expectedVal: Double? {
        dayForecast?.expected
    }

    private var safeOverallMin: Double {
        min(overallMinimum, overallMaximum)
    }

    private var safeOverallMax: Double {
        max(overallMinimum, overallMaximum)
    }

    private var isFlatOverallRange: Bool {
        safeOverallMax - safeOverallMin == 0
    }

    private func normalized(_ value: Double) -> CGFloat {
        if isFlatOverallRange { return 0 }
        let clamped = min(max(value, safeOverallMin), safeOverallMax)
        return CGFloat((clamped - safeOverallMin) / (safeOverallMax - safeOverallMin))
    }

    private var rangeText: String {
        guard let f = dayForecast else { return "—" }
        // Show as integers if >= 1, else one decimal for small numbers
        let minStr: String
        let maxStr: String
        if f.min >= 1 || f.max >= 1 {
            minStr = String(format: "%.0f", f.min)
            maxStr = String(format: "%.0f", f.max)
        } else {
            // The forecast is so low that it get hard to say
            minStr = String(format: "%.0f", 0)
            maxStr = String(format: "%.0f", 1)
        }
        return minStr == maxStr ? "\(minStr) kWh" : "\(minStr)–\(maxStr) kWh"
    }

    private var expectedText: String? {
        guard let e = expectedVal else { return nil }
        let text: String = e >= 1 ? String(format: "%.0f", e) : String(format: "%.1f", e)
        return "\(text) kWh"
    }

    var body: some View {
        HStack(spacing: 10) {
            // Day label
            Text(dayLabel)
                .font(.caption2)
                .frame(width: 170, alignment: .leading)

            // Bar with range and expected
            GeometryReader { geo in
                let width = geo.size.width
                let trackHeight: CGFloat = 6
                let corner: CGFloat = trackHeight / 2

                // Positions
                let startX = width * normalized(minVal)
                let endX = width * normalized(maxVal)
                let expectedX: CGFloat? = expectedVal.map { width * normalized($0) }

                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(Color.gray.opacity(0.25))
                        .frame(height: trackHeight)

                    // Range segment
                    if hasData {
                        let segX = min(startX, endX)
                        let segW = max(endX - startX, 2)  // ensure visible even if min≈max
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .fill(Color.accentColor.opacity(0.7))
                            .frame(width: segW, height: trackHeight)
                            .offset(x: segX)
                            .animation(.easeInOut(duration: 0.2), value: segW)
                    }

                    // Expected marker
                    if let x = expectedX, hasData {
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: 2, height: trackHeight + 6)
                            .offset(x: min(max(0, x - 1), width - 2))
                            .shadow(radius: 0.5)
                            .accessibilityHidden(true)
                    }
                }
                .frame(height: max(trackHeight, 12))
            }
            .frame(height: 14)

            // Values
            VStack(alignment: .trailing, spacing: 2) {
                Text(rangeText)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let expectedText {
                    Text(expectedText)
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .frame(width: 70, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, minHeight: 28, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(dayLabel))
        .accessibilityValue(Text(accessibilityDescription))
    }

    private var accessibilityDescription: String {
        guard let f = dayForecast else { return "No forecast" }
        let minStr = String(format: "%.1f", f.min)
        let maxStr = String(format: "%.1f", f.max)
        let expectedStr = String(format: "%.1f", f.expected)
        return "Range \(minStr) to \(maxStr) kilowatt-hours. Expected \(expectedStr) kilowatt-hours."
    }
}

#Preview {
    HStack {
        VStack(spacing: 8) {
            DayForecastView(
                dayForecast: .init(min: 3, max: 6, expected: 5.6),
                dayLabel: "Today",
                overallMinimum: 0,
                overallMaximum: 22.4
            )
            DayForecastView(
                dayForecast: .init(min: 10.3, max: 15.4, expected: 12.4),
                dayLabel: "Tomorrow",
                overallMinimum: 0,
                overallMaximum: 22.4
            )
            DayForecastView(
                dayForecast: .init(min: 15.4, max: 22.4, expected: 20.1),
                dayLabel: "After tomorrow",
                overallMinimum: 0,
                overallMaximum: 22.4
            )
            DayForecastView(
                dayForecast: nil,
                dayLabel: "No data",
                overallMinimum: 0,
                overallMaximum: 22.4
            )
        }
        .padding()
        .frame(maxWidth: 500)

        Spacer()
    }

}
