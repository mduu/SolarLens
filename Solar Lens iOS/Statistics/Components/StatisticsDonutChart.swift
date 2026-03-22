import Charts
import SwiftUI

struct StatisticsDonutChart: View {
    var leftLabel: String
    var leftValue: Double
    var leftColor: Color
    var leftSubtitle: LocalizedStringKey?
    var rightLabel: String
    var rightValue: Double
    var rightColor: Color
    var rightSubtitle: LocalizedStringKey?
    var total: Double

    @Environment(\.colorScheme) private var colorScheme

    struct SliceData: Identifiable {
        let id = UUID()
        let type: String
        let value: Double
    }

    private var isEmpty: Bool {
        total <= 0 && leftValue <= 0 && rightValue <= 0
    }

    private var useMWh: Bool {
        abs(total) >= 1_000_000
    }

    private func formatValue(_ value: Double) -> String {
        if useMWh {
            return String(format: "%.1f", value / 1_000_000)
        }
        return String(format: "%.1f", value / 1000)
    }

    private var unitLabel: String {
        useMWh ? "MWh" : "kWh"
    }

    var body: some View {
        let slices: [SliceData] = [
            SliceData(type: rightLabel, value: max(0, rightValue)),
            SliceData(type: leftLabel, value: max(0, leftValue)),
        ]

        ZStack {
            VStack(spacing: 2) {
                HStack {
                    Text(LocalizedStringKey(leftLabel))
                        .foregroundColor(leftColor)
                        .font(.system(size: 14, weight: .medium))

                    Spacer()

                    Text(LocalizedStringKey(rightLabel))
                        .foregroundColor(rightColor)
                        .font(.system(size: 14, weight: .medium))
                }

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(formatValue(leftValue)) \(unitLabel)")
                            .font(.footnote)
                        if let leftSubtitle {
                            Text(leftSubtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(formatValue(rightValue)) \(unitLabel)")
                            .font(.footnote)
                        if let rightSubtitle {
                            Text(rightSubtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Chart {
                if isEmpty {
                    SectorMark(
                        angle: .value("kWh", 100),
                        innerRadius: 40,
                        outerRadius: 50
                    )
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1))
                } else {
                    ForEach(slices) { slice in
                        SectorMark(
                            angle: .value("kWh", slice.value),
                            innerRadius: 40,
                            outerRadius: 50,
                            angularInset: 2
                        )
                        .cornerRadius(5)
                        .foregroundStyle(by: .value("Source", slice.type))
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .chartForegroundStyleScale([
                leftLabel: leftColor,
                rightLabel: rightColor,
            ])
            .chartLegend(.hidden)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let anchor = chartProxy.plotFrame {
                        let frame = geometry[anchor]
                        VStack(spacing: 0) {
                            Text("Total")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(formatValue(total))
                                .font(.footnote)
                            Text(unitLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
        }
        .frame(maxHeight: 110)
    }
}
