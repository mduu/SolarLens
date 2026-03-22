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
        let kWh = self / 1000
        if abs(kWh) >= 1000 {
            let mWh = kWh / 1000
            return withUnit
                ? "\(String(format: "%.1f", mWh)) MWh"
                : String(format: "%.1f", mWh)
        }
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
