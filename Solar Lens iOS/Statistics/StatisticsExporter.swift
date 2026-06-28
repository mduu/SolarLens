internal import Foundation

enum ExportFormat {
    case csv
    case xlsx
}

enum StatisticsExporter {

    /// Generates a CSV or XLSX file from statistics data and returns its temporary URL.
    static func export(
        data: [DayStatistic],
        periodLabel: String,
        format: ExportFormat
    ) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let sortedData = data.sorted { $0.day < $1.day }

        let startDate = sortedData.first.map { dateFormatter.string(from: $0.day) } ?? "unknown"
        let endDate = sortedData.last.map { dateFormatter.string(from: $0.day) } ?? "unknown"
        let baseName = "SolarLens_\(startDate)_\(endDate)"

        let tempDir = FileManager.default.temporaryDirectory

        switch format {
        case .csv:
            let csvURL = tempDir.appendingPathComponent("\(baseName).csv")
            try generateCSV(data: sortedData, dateFormatter: dateFormatter, to: csvURL)
            return csvURL
        case .xlsx:
            let xlsxURL = tempDir.appendingPathComponent("\(baseName).xlsx")
            try generateXLSX(data: sortedData, dateFormatter: dateFormatter, to: xlsxURL)
            return xlsxURL
        }
    }

    /// Generates a high-resolution CSV or XLSX file from raw per-interval
    /// samples — one timestamped row per interval, including battery columns
    /// (0 for non-owners). Used for the hourly custom-range export.
    static func exportIntervals(
        data: [MainDataItem],
        format: ExportFormat
    ) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let fileDateFormatter = DateFormatter()
        fileDateFormatter.dateFormat = "yyyy-MM-dd"

        let sortedData = data.sorted { $0.date < $1.date }
        let startDate = sortedData.first.map { fileDateFormatter.string(from: $0.date) } ?? "unknown"
        let endDate = sortedData.last.map { fileDateFormatter.string(from: $0.date) } ?? "unknown"
        let baseName = "SolarLens_hourly_\(startDate)_\(endDate)"

        let tempDir = FileManager.default.temporaryDirectory

        switch format {
        case .csv:
            let url = tempDir.appendingPathComponent("\(baseName).csv")
            try generateIntervalsCSV(data: sortedData, dateFormatter: dateFormatter, to: url)
            return url
        case .xlsx:
            let url = tempDir.appendingPathComponent("\(baseName).xlsx")
            try generateIntervalsXLSX(data: sortedData, dateFormatter: dateFormatter, to: url)
            return url
        }
    }

    private static let intervalHeaders = [
        "DateTime",
        "Production (kWh)",
        "Consumption (kWh)",
        "Grid Import (kWh)",
        "Grid Export (kWh)",
        "Battery Charge (kWh)",
        "Battery Discharge (kWh)",
    ]

    private static func generateIntervalsCSV(
        data: [MainDataItem],
        dateFormatter: DateFormatter,
        to url: URL
    ) throws {
        var csv = intervalHeaders.joined(separator: ";") + "\n"
        for item in data {
            let cols = [
                dateFormatter.string(from: item.date),
                String(format: "%.3f", item.productionOverTimeWatthours / 1000),
                String(format: "%.3f", item.consumptionOverTimeWatthours / 1000),
                String(format: "%.3f", item.importedOverTimeWhatthours / 1000),
                String(format: "%.3f", item.exportedOverTimeWhatthours / 1000),
                String(format: "%.3f", item.batteryChargedWh / 1000),
                String(format: "%.3f", item.batteryDischargedWh / 1000),
            ]
            csv += cols.joined(separator: ";") + "\n"
        }
        try csv.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func generateIntervalsXLSX(
        data: [MainDataItem],
        dateFormatter: DateFormatter,
        to url: URL
    ) throws {
        var cells: [SimpleXLSXWriter.Cell] = []
        for (col, header) in intervalHeaders.enumerated() {
            cells.append(.init(column: col, row: 0, value: header, isNumber: false))
        }
        for (rowIndex, item) in data.enumerated() {
            let row = rowIndex + 1
            cells.append(.init(column: 0, row: row, value: dateFormatter.string(from: item.date), isNumber: false))
            cells.append(.init(column: 1, row: row, value: String(format: "%.3f", item.productionOverTimeWatthours / 1000), isNumber: true))
            cells.append(.init(column: 2, row: row, value: String(format: "%.3f", item.consumptionOverTimeWatthours / 1000), isNumber: true))
            cells.append(.init(column: 3, row: row, value: String(format: "%.3f", item.importedOverTimeWhatthours / 1000), isNumber: true))
            cells.append(.init(column: 4, row: row, value: String(format: "%.3f", item.exportedOverTimeWhatthours / 1000), isNumber: true))
            cells.append(.init(column: 5, row: row, value: String(format: "%.3f", item.batteryChargedWh / 1000), isNumber: true))
            cells.append(.init(column: 6, row: row, value: String(format: "%.3f", item.batteryDischargedWh / 1000), isNumber: true))
        }
        try SimpleXLSXWriter.write(cells: cells, to: url)
    }

    // MARK: - CSV

    private static func generateCSV(
        data: [DayStatistic],
        dateFormatter: DateFormatter,
        to url: URL
    ) throws {
        var csv = "Date;Production (kWh);Consumption (kWh);Grid Import (kWh);Grid Export (kWh)\n"

        for stat in data {
            let date = dateFormatter.string(from: stat.day)
            let production = String(format: "%.2f", stat.production / 1000)
            let consumption = String(format: "%.2f", stat.consumption / 1000)
            let imported = String(format: "%.2f", stat.imported / 1000)
            let exported = String(format: "%.2f", stat.exported / 1000)
            csv += "\(date);\(production);\(consumption);\(imported);\(exported)\n"
        }

        try csv.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - XLSX

    private static func generateXLSX(
        data: [DayStatistic],
        dateFormatter: DateFormatter,
        to url: URL
    ) throws {
        let headers = ["Date", "Production (kWh)", "Consumption (kWh)", "Grid Import (kWh)", "Grid Export (kWh)"]
        var cells: [SimpleXLSXWriter.Cell] = []

        // Header row
        for (col, header) in headers.enumerated() {
            cells.append(.init(column: col, row: 0, value: header, isNumber: false))
        }

        // Data rows
        for (rowIndex, stat) in data.enumerated() {
            let row = rowIndex + 1
            cells.append(.init(column: 0, row: row, value: dateFormatter.string(from: stat.day), isNumber: false))
            cells.append(.init(column: 1, row: row, value: String(format: "%.2f", stat.production / 1000), isNumber: true))
            cells.append(.init(column: 2, row: row, value: String(format: "%.2f", stat.consumption / 1000), isNumber: true))
            cells.append(.init(column: 3, row: row, value: String(format: "%.2f", stat.imported / 1000), isNumber: true))
            cells.append(.init(column: 4, row: row, value: String(format: "%.2f", stat.exported / 1000), isNumber: true))
        }

        try SimpleXLSXWriter.write(cells: cells, to: url)
    }
}
