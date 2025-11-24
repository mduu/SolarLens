import Charts
import SwiftUI

struct WeekOverviewChartView: View {
    var weekData: [DayStatistic]?

    // Enum to represent the different energy types for the chart
    private enum EnergyType: String, CaseIterable {
        case consumption = "Consumption"
        case production = "Solar"
        case imported = "Grid Import"
        case exported = "Grid Export"

        var color: Color {
            switch self {
            case .consumption:
                return .blue.opacity(0.9)
            case .production:
                return .yellow.opacity(0.9)
            case .imported:
                return .red.opacity(0.9)
            case .exported:
                return .orange.opacity(0.9)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let weekData = weekData, !weekData.isEmpty {
                Chart {
                    ForEach(weekData, id: \.day) { daySum in
                        // Production bar
                        BarMark(
                            x: .value("Day", daySum.day, unit: .day),
                            y: .value("Energy", daySum.production / 1000)
                        )
                        .foregroundStyle(by: .value("Type", EnergyType.production.rawValue))
                        .position(by: .value("Type", EnergyType.production.rawValue))

                        // Consumption bar
                        BarMark(
                            x: .value("Day", daySum.day, unit: .day),
                            y: .value("Energy", daySum.consumption / 1000)
                        )
                        .foregroundStyle(by: .value("Type", EnergyType.consumption.rawValue))
                        .position(by: .value("Type", EnergyType.consumption.rawValue))

                        // Grid Import bar
                        BarMark(
                            x: .value("Day", daySum.day, unit: .day),
                            y: .value("Energy", daySum.imported / 1000)
                        )
                        .foregroundStyle(by: .value("Type", EnergyType.imported.rawValue))
                        .position(by: .value("Type", EnergyType.imported.rawValue))

                        // Grid Export bar
                        BarMark(
                            x: .value("Day", daySum.day, unit: .day),
                            y: .value("Energy", daySum.exported / 1000)
                        )
                        .foregroundStyle(by: .value("Type", EnergyType.exported.rawValue))
                        .position(by: .value("Type", EnergyType.exported.rawValue))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.weekday(.abbreviated))
                                    #if os(tvOS)
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                    #endif
                            }
                        }
                        AxisGridLine()
                        AxisTick()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let energy = value.as(Double.self) {
                                Text("\(energy, specifier: "%.0f") kWh")
                                    #if os(tvOS)
                                        .foregroundColor(.white)
                                    #endif
                            }
                        }
                    }
                }
                .chartForegroundStyleScale([
                    EnergyType.consumption.rawValue: EnergyType.consumption.color,
                    EnergyType.production.rawValue: EnergyType.production.color,
                    EnergyType.imported.rawValue: EnergyType.imported.color,
                    EnergyType.exported.rawValue: EnergyType.exported.color,
                ])
                .chartLegend(position: .bottom, alignment: .center)
                .frame(height: 300)
            } else {
                ContentUnavailableView(
                    "No Data Available",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Weekly statistics will appear here when data is available.")
                )
                .frame(height: 300)
            }
        }
        .padding()
    }
}

#Preview("With Data") {
    let calendar = Calendar.current
    let today = Date()

    let sampleData: [DayStatistic] = (0..<7).map { daysAgo in
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
        return DayStatistic(
            day: date,
            consumption: Double.random(in: 15...35),
            production: Double.random(in: 20...40),
            imported: Double.random(in: 5...15),
            exported: Double.random(in: 10...25)
        )
    }.reversed()

    return WeekOverviewChartView(weekData: sampleData)
        .frame(maxWidth: 500, maxHeight: 300)
}

#Preview("No Data") {
    WeekOverviewChartView(weekData: nil)
}

#Preview("Empty Array") {
    WeekOverviewChartView(weekData: [])
}
