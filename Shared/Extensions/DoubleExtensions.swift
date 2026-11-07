internal import Foundation

extension Double {

    func formatWattsAsKiloWatts(widthUnit: Bool = false) -> String {
        widthUnit
            ? "\((self / 1000).localized(decimals: 1)) \(getUnitKw())"
            : (self / 1000).localized(decimals: 1)
    }

    func formatAsKiloWatts(widthUnit: Bool = false) -> String {
        widthUnit
            ? "\(self.localized(decimals: 1)) \(getUnitKw())"
            : self.localized(decimals: 1)
    }

    func formatAsKiloWattsHours(widthUnit: Bool = false) -> String {
        widthUnit
            ? "\(self.localized(decimals: 0)) \(getUnitKwh())"
            : self.localized(decimals: 0)
    }

    func formatWattHoursAsKiloWattsHours(widthUnit: Bool = false) -> String {
        widthUnit
            ? "\((self / 1000).localized(decimals: 1)) \(getUnitKwh())"
            : (self / 1000).localized(decimals: 1)
    }

    func formatWattHoursAsMegaWattsHours(widthUnit: Bool = false) -> String {
        widthUnit
        ? "\((self / 1_000_000).localized(decimals: 2)) \(getUnitMwh())"
        : (self / 1_000_000).localized(decimals: 2)
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
                ? "\(mWh.localized(decimals: 1)) MWh"
                : mWh.localized(decimals: 1)
        }
        let kWh = self / 1000
        return withUnit
            ? "\(kWh.localized(decimals: 1)) kWh"
            : kWh.localized(decimals: 1)
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

extension Double {

    /// The value as the device's locale writes it — decimal separator and
    /// digit grouping included — with a fixed number of decimals.
    ///
    /// For what the user reads only. Exports and API payloads keep their
    /// machine formats, which is why they never call this.
    func localized(decimals: Int) -> String {
        // Rounded here first, so a −0.04 that rounds to zero is written "0.0"
        // and not "-0.0".
        let factor = pow(10.0, Double(decimals))
        var rounded = (self * factor).rounded() / factor
        if rounded == 0 { rounded = 0 }
        return rounded.formatted(.number.precision(.fractionLength(decimals)))
    }
}

extension Int {

    /// The same as `Double.localized(decimals:)`, for a whole number that is
    /// shown with decimals — "3.0 kW".
    func localized(decimals: Int) -> String {
        Double(self).localized(decimals: decimals)
    }
}
