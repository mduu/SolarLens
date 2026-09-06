import SwiftUI

/// The four series a statistics bar chart draws.
///
/// One definition for the colours, the names, the toggle bar and the values
/// table, so a colour or a label can never say two different things in two
/// places. `markKey` is what Swift Charts groups and styles marks by.
enum StatisticsSeries: String, CaseIterable, Identifiable {
    case production
    case consumption
    case imported
    case exported

    var id: String { rawValue }

    /// The value the chart's foreground-style scale is keyed on. Not shown to
    /// the user, so it stays untranslated.
    var markKey: String {
        switch self {
        case .production: "Solar"
        case .consumption: "Consumption"
        case .imported: "Grid Import"
        case .exported: "Grid Export"
        }
    }

    var label: LocalizedStringKey {
        switch self {
        case .production: "Solar"
        case .consumption: "Consumption"
        case .imported: "Import"
        case .exported: "Export"
        }
    }

    var color: Color {
        switch self {
        case .production: .orange
        case .consumption: .blue.opacity(0.9)
        case .imported: Color(red: 1.0, green: 0.3, blue: 0.15)
        case .exported: .purple.opacity(0.9)
        }
    }

    /// This series' figure in one bucket, in watt-hours.
    func value(in bucket: DayStatistic) -> Double {
        switch self {
        case .production: bucket.production
        case .consumption: bucket.consumption
        case .imported: bucket.imported
        case .exported: bucket.exported
        }
    }
}
