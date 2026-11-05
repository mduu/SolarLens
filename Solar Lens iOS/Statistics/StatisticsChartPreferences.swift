import SwiftUI

/// Which chart each statistics period shows, remembered per period.
///
/// Someone who prefers the bars for the week has not thereby asked for them
/// everywhere — so every period keeps its own choice. The map's metric is the
/// opposite: whoever is looking at self-consumption wants to keep looking at
/// it while paging from month to year, so that one is shared.
struct StatisticsChartPreferences: DynamicProperty {

    @AppStorage("stats.week.chartStyle") private var weekStyle = StatisticsChartStyle.flow
    @AppStorage("stats.month.chartStyle") private var monthStyle = StatisticsChartStyle.flow
    @AppStorage("stats.year.chartStyle") private var yearStyle = StatisticsChartStyle.flow
    @AppStorage("stats.overall.chartStyle") private var overallStyle = StatisticsChartStyle.flow
    @AppStorage("stats.custom.chartStyle") private var customStyle = StatisticsChartStyle.flow

    @AppStorage("stats.map.metric") private var mapMetric = MapMetric.autarky

    /// The styles a period can be drawn in, in picker order. Empty for Today,
    /// which only has its intraday chart; a custom range has no fixed shape
    /// to lay a map out in.
    static func styles(for period: StatisticsPeriod) -> [StatisticsChartStyle] {
        switch period {
        case .today: []
        case .week, .month, .year, .overall: [.flow, .balance, .map, .bars]
        case .custom: [.flow, .balance, .bars]
        }
    }

    func style(for period: StatisticsPeriod) -> Binding<StatisticsChartStyle> {
        switch period {
        case .week: $weekStyle
        case .month: $monthStyle
        case .year: $yearStyle
        case .overall: $overallStyle
        case .custom: $customStyle
        case .today: .constant(.flow)
        }
    }

    /// The figure the map tints its tiles by.
    var metric: Binding<MapMetric> { $mapMetric }
}
