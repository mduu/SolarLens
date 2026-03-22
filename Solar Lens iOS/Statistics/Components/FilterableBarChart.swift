import Charts
import SwiftUI

enum XLabelFormat {
    case weekday
    case dayOfMonth
    case isoWeekNumber
    case month
    case monthNarrow
    case year
}

struct FilterableBarChart: View {
    var data: [DayStatistic]
    var xUnit: Calendar.Component
    var xLabelFormat: XLabelFormat
    @Binding var showProduction: Bool
    @Binding var showConsumption: Bool
    @Binding var showImport: Bool
    @Binding var showExport: Bool
    var chartHeight: CGFloat = 200

    private let productionColor: Color = .orange
    private let consumptionColor: Color = .blue.opacity(0.9)
    private let importColor: Color = Color(red: 1.0, green: 0.3, blue: 0.15)
    private let exportColor: Color = .purple.opacity(0.9)

    /// Max Wh value across all data — drives kWh vs MWh decision
    private var maxWh: Double {
        data.map { max($0.production, $0.consumption, $0.imported, $0.exported) }.max() ?? 0
    }

    private var useMWh: Bool { maxWh >= 1_000_000 }
    private var yDivisor: Double { useMWh ? 1_000_000 : 1000 }

    /// How many data points to skip between x-axis labels so they stay readable
    private var xAxisStride: Int {
        let count = data.count
        switch xLabelFormat {
        case .weekday:
            return 1
        case .dayOfMonth:
            if count <= 14 { return 2 }
            if count <= 60 { return 7 }
            // > ~120 days: switch to month-based stride
            return 30
        case .isoWeekNumber:
            if count <= 5 { return 1 }
            // > 5 weeks: stride by ~4 weeks (month-ish)
            return 4
        case .month, .monthNarrow:
            return count > 9 ? 2 : 1
        case .year:
            return 1
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            if data.isEmpty {
                ContentUnavailableView(
                    "No Data Available",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Statistics will appear here when data is available.")
                )
                .frame(height: 250)
            } else {
                Chart {
                    ForEach(data, id: \.day) { item in
                        if showProduction {
                            BarMark(
                                x: .value("Period", item.day, unit: xUnit),
                                y: .value("Energy", item.production / yDivisor)
                            )
                            .foregroundStyle(by: .value("Type", "Solar"))
                            .position(by: .value("Type", "Solar"))
                        }
                        if showConsumption {
                            BarMark(
                                x: .value("Period", item.day, unit: xUnit),
                                y: .value("Energy", item.consumption / yDivisor)
                            )
                            .foregroundStyle(by: .value("Type", "Consumption"))
                            .position(by: .value("Type", "Consumption"))
                        }
                        if showImport {
                            BarMark(
                                x: .value("Period", item.day, unit: xUnit),
                                y: .value("Energy", item.imported / yDivisor)
                            )
                            .foregroundStyle(by: .value("Type", "Grid Import"))
                            .position(by: .value("Type", "Grid Import"))
                        }
                        if showExport {
                            BarMark(
                                x: .value("Period", item.day, unit: xUnit),
                                y: .value("Energy", item.exported / yDivisor)
                            )
                            .foregroundStyle(by: .value("Type", "Grid Export"))
                            .position(by: .value("Type", "Grid Export"))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: xUnit, count: xAxisStride)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                switch xLabelFormat {
                                case .weekday:
                                    Text(date, format: .dateTime.weekday(.abbreviated))
                                case .dayOfMonth:
                                    if data.count > 120 {
                                        Text(date, format: .dateTime.month(.abbreviated))
                                    } else if data.count > 14 {
                                        Text(date, format: .dateTime.day(.twoDigits).month(.abbreviated))
                                    } else {
                                        Text(date, format: .dateTime.day())
                                    }
                                case .isoWeekNumber:
                                    if data.count > 5 {
                                        Text(date, format: .dateTime.month(.abbreviated))
                                    } else {
                                        Text("W\(Calendar(identifier: .iso8601).component(.weekOfYear, from: date))")
                                    }
                                case .month, .monthNarrow:
                                    let cal = Calendar.current
                                    let y = cal.component(.year, from: date) % 100
                                    let m = cal.component(.month, from: date)
                                    Text("\(y)/\(m)")
                                case .year:
                                    Text(date, format: .dateTime.year())
                                }
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
                                // Convert back to Wh for the adaptive formatter
                                Text((energy * yDivisor).formatWattHoursAdaptive(withUnit: true))
                            }
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "Solar": productionColor,
                    "Consumption": consumptionColor,
                    "Grid Import": importColor,
                    "Grid Export": exportColor,
                ])
                .chartLegend(.hidden)
                .frame(height: chartHeight)
            }

            // Toggle buttons
            seriesToggleBar
        }
    }

    private var seriesToggleBar: some View {
        HStack(spacing: 6) {
            SeriesToggle(label: "Solar", color: productionColor, isOn: $showProduction)
            SeriesToggle(label: "Consumption", color: consumptionColor, isOn: $showConsumption)
            SeriesToggle(label: "Import", color: importColor, isOn: $showImport)
            SeriesToggle(label: "Export", color: exportColor, isOn: $showExport)
        }
    }
}
