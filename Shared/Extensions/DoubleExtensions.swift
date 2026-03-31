internal import Foundation

extension Double {

    func formatWattsAsKiloWatts(widthUnit: Bool = false) -> String {
        widthUnit
            ? "\(String(format: "%.1f",Double(self) / 1000)) \(getUnitKw())"
            : String(format: "%.1f", Double(self) / 1000)
    }

    func formatAsKiloWatts(widthUnit: Bool = false) -> String {
        widthUnit
            ? "\(String(format: "%.1f", self)) \(getUnitKw())"
            : String(format: "%.1f", self)
    }

    func formatAsKiloWattsHours(widthUnit: Bool = false) -> String {
        widthUnit
            ? "\(String(format: "%.0f", self)) \(getUnitKwh())"
            : String(format: "%.0f", self)
    }

    func formatWattHoursAsKiloWattsHours(widthUnit: Bool = false) -> String {
        widthUnit
            ? "\(String(format: "%.1f", Double(self) / 1000))  \(getUnitKwh())"
            : String(format: "%.1f", Double(self) / 1000)
    }

    func formatWattHoursAsMegaWattsHours(widthUnit: Bool = false) -> String {
        widthUnit
        ? "\(String(format: "%.2f", Double(self) / 10000000.0))  \(getUnitMwh())"
        : String(format: "%.2f", Double(self) / 10000000.0)
    }

    /// Formats Wh as kWh or MWh depending on magnitude (>= 1000 kWh → MWh).
    func formatWattHoursAdaptive(withUnit: Bool = false) -> String {
        let useMWh = abs(self / 1000) >= 1000
        return formatWattHours(asMWh: useMWh, withUnit: withUnit)
    }

    /// Formats Wh as kWh or MWh based on an explicit flag (for consistent units across a group of values).
    func formatWattHours(asMWh: Bool, withUnit: Bool = false) -> String {
        if asMWh {
            let mWh = self / 1_000_000
            return withUnit
                ? "\(String(format: "%.1f", mWh)) MWh"
                : String(format: "%.1f", mWh)
        }
        let kWh = self / 1000
        return withUnit
            ? "\(String(format: "%.1f", kWh)) kWh"
            : String(format: "%.1f", kWh)
    }

    func formatIntoPercentage() -> String {
        String(
            format: "%.0f%%",
            Double(self)
        )
    }

    private func getUnitKw() -> String {
        "kW"
    }

    private func getUnitKwh() -> String {
        "kWh"
    }

    private func getUnitMwh() -> String {
        "MWh"
    }
}

extension Double? {
    func formatIntoPercentage() -> String {
        String(
            format: "%.0f%%",
            Double(self ?? 0)
        )
    }
}
