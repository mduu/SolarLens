import Charts
import SwiftUI

enum XLabelFormat {
    case weekday
    case dayOfMonth
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
                                y: .value("Energy", item.production / 1000)
                            )
                            .foregroundStyle(by: .value("Type", "Solar"))
                            .position(by: .value("Type", "Solar"))
                        }
                        if showConsumption {
                            BarMark(
                                x: .value("Period", item.day, unit: xUnit),
                                y: .value("Energy", item.consumption / 1000)
                            )
                            .foregroundStyle(by: .value("Type", "Consumption"))
                            .position(by: .value("Type", "Consumption"))
                        }
                        if showImport {
                            BarMark(
                                x: .value("Period", item.day, unit: xUnit),
                                y: .value("Energy", item.imported / 1000)
                            )
                            .foregroundStyle(by: .value("Type", "Grid Import"))
                            .position(by: .value("Type", "Grid Import"))
                        }
                        if showExport {
                            BarMark(
                                x: .value("Period", item.day, unit: xUnit),
                                y: .value("Energy", item.exported / 1000)
                            )
                            .foregroundStyle(by: .value("Type", "Grid Export"))
                            .position(by: .value("Type", "Grid Export"))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: xUnit, count: xLabelFormat == .dayOfMonth ? 5 : 1)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                switch xLabelFormat {
                                case .weekday:
                                    Text(date, format: .dateTime.weekday(.abbreviated))
                                case .dayOfMonth:
                                    Text(date, format: .dateTime.day())
                                case .month:
                                    Text(date, format: .dateTime.month(.abbreviated))
                                case .monthNarrow:
                                    Text(date, format: .dateTime.month(.narrow))
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
                                Text("\(energy, specifier: "%.0f") kWh")
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
