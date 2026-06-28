internal import Foundation

struct TariffCalculator {

    /// Calculate total grid import cost in main currency units (e.g. CHF, EUR)
    static func gridImportCost(
        data: [MainDataItem],
        tariffSettings: TariffSettingsV3Response?,
        fallbackTariff: TariffV1Response?
    ) -> Double {
        guard let config = tariffSettings?.purchase else {
            return gridImportCostV1(data: data, tariff: fallbackTariff)
        }

        return data.reduce(0.0) { total, item in
            let ratePerKwh = fullPurchaseRate(for: item.date, config: config) / 100
            return total + (item.importedOverTimeWhatthours / 1000) * ratePerKwh
        }
    }

    /// Calculate total grid export revenue in main currency units
    static func gridExportRevenue(
        data: [MainDataItem],
        tariffSettings: TariffSettingsV3Response?,
        fallbackTariff: TariffV1Response?
    ) -> Double {
        guard let config = tariffSettings?.feedIn else {
            return gridExportRevenueV1(data: data, tariff: fallbackTariff)
        }

        return data.reduce(0.0) { total, item in
            let ratePerKwh = resolveRate(for: item.date, config: config) / 100
            return total + (item.exportedOverTimeWhatthours / 1000) * ratePerKwh
        }
    }

    /// Value of the grid import the battery avoided, in main currency units:
    /// the energy it discharged, valued at the import tariff in force at each
    /// moment. This is the figure behind the "Grid import avoided" headline.
    ///
    /// Unlike `batteryNetBenefit`, this does NOT subtract the cost of charging.
    /// Charging from solar surplus is not a cash outlay, and netting it makes
    /// the figure misleading over a partial cycle (e.g. mid-day, when the
    /// battery has charged but not yet discharged) — it would read negative
    /// even though the battery is working normally.
    static func avoidedImportValue(
        data: [MainDataItem],
        tariffSettings: TariffSettingsV3Response?,
        fallbackTariff: TariffV1Response?,
        dynamicImport: DynamicTariff? = nil
    ) -> Double {
        data.reduce(0.0) { total, item in
            let rate = importRateCHF(
                at: item.date,
                dynamicImport: dynamicImport,
                tariffSettings: tariffSettings,
                fallbackTariff: fallbackTariff
            )
            return total + (item.batteryDischargedWh / 1000) * rate
        }
    }

    /// Feed-in revenue forgone because surplus charged the battery instead of
    /// being exported, in main currency units. ~0 when export isn't billed.
    static func forgoneExportRevenue(
        data: [MainDataItem],
        tariffSettings: TariffSettingsV3Response?,
        fallbackTariff: TariffV1Response?
    ) -> Double {
        data.reduce(0.0) { total, item in
            let rate = exportRateCHF(
                at: item.date,
                tariffSettings: tariffSettings,
                fallbackTariff: fallbackTariff
            )
            return total + (item.batteryChargedWh / 1000) * rate
        }
    }

    /// Net money a battery adds over the period, in main currency units:
    /// the grid import it avoided minus the feed-in revenue it forwent.
    static func batteryNetBenefit(
        data: [MainDataItem],
        tariffSettings: TariffSettingsV3Response?,
        fallbackTariff: TariffV1Response?,
        dynamicImport: DynamicTariff? = nil
    ) -> Double {
        avoidedImportValue(
            data: data, tariffSettings: tariffSettings,
            fallbackTariff: fallbackTariff, dynamicImport: dynamicImport
        ) - forgoneExportRevenue(
            data: data, tariffSettings: tariffSettings, fallbackTariff: fallbackTariff
        )
    }

    /// Import rate in main currency units per kWh, preferring the dynamic
    /// tariff when it covers the moment, then the V3 purchase config, then V1.
    static func importRateCHF(
        at date: Date,
        dynamicImport: DynamicTariff?,
        tariffSettings: TariffSettingsV3Response?,
        fallbackTariff: TariffV1Response?
    ) -> Double {
        if let dynamic = dynamicImport?.priceCHF(at: date) {
            return dynamic
        }
        if let config = tariffSettings?.purchase {
            return fullPurchaseRate(for: date, config: config) / 100
        }
        return (fallbackTariff?.highTariff ?? fallbackTariff?.singleTariff ?? 0) / 100
    }

    /// Export / feed-in rate in main currency units per kWh.
    static func exportRateCHF(
        at date: Date,
        tariffSettings: TariffSettingsV3Response?,
        fallbackTariff: TariffV1Response?
    ) -> Double {
        if let config = tariffSettings?.feedIn {
            return resolveRate(for: date, config: config) / 100
        }
        return (fallbackTariff?.directMarketing ?? 0) / 100
    }

    // MARK: - Rate Resolution

    /// Full import / purchase rate in cents/Rappen per kWh, summing every
    /// per-kWh component of the real consumer price:
    /// - **Energietarif** — energy tariff (`singleTariff` / `variableTariff`)
    /// - **Netzentgelte** — grid fees: flat per-kWh (`gridFees.fixed`) and/or
    ///   time-of-use (`gridFees.variable`)
    /// - **Steuern und Abgaben** — per-kWh taxes & duties (`taxesAndDuties.kWh`)
    ///
    /// Only genuinely monthly fees (`taxesAndDuties.month`) are excluded — they
    /// aren't avoided per kWh. The energy tariff alone understates the real
    /// price, often by ~half (grid fees + taxes are the rest).
    static func fullPurchaseRate(for date: Date, config: TariffConfig) -> Double {
        var rate = resolveRate(for: date, config: config)  // Energietarif

        // Netzentgelte (grid fees) — both are per-kWh; a config typically has
        // one or the other (flat vs time-of-use).
        if let gridFees = config.gridFees {
            if let flatGridFee = gridFees.fixed {
                rate += flatGridFee
            }
            if let gridVariable = gridFees.variable {
                rate += resolveVariableRate(
                    for: date,
                    prices: gridVariable.prices,
                    season: gridVariable.commonSeason
                )
            }
        }

        // Steuern und Abgaben (per kWh).
        if let taxPerKwh = config.taxesAndDuties?.kWh {
            rate += taxPerKwh
        }

        return rate
    }

    /// Resolve the applicable energy tariff rate (in cents/Rappen per kWh) for
    /// a given timestamp.
    static func resolveRate(for date: Date, config: TariffConfig) -> Double {
        switch config.tariffType {
        case "single":
            return config.singleTariff?.price ?? 0

        case "variable":
            guard let variable = config.variableTariff,
                  let prices = variable.prices
            else { return config.singleTariff?.price ?? 0 }

            return resolveVariableRate(
                for: date,
                prices: prices,
                season: effectiveSeason(for: date, variable: variable)
            )

        default:
            // Unknown/blank tariff type: fall back to whatever price is present
            // rather than silently returning 0 (which would zero out savings).
            if let single = config.singleTariff?.price {
                return single
            }
            if let variable = config.variableTariff, let prices = variable.prices {
                return resolveVariableRate(
                    for: date,
                    prices: prices,
                    season: effectiveSeason(for: date, variable: variable)
                )
            }
            return 0
        }
    }

    /// Resolve a price from a (prices, schedule) pair for a timestamp.
    private static func resolveVariableRate(
        for date: Date,
        prices: TariffPrices?,
        season: TariffSeason?
    ) -> Double {
        guard let prices else { return 0 }
        let option = resolveTariffOption(for: date, season: season)
        return priceForOption(option, prices: prices)
    }

    /// Pick the winter schedule when winter time is enabled and the date falls
    /// in the winter window, otherwise the common schedule. The SM config does
    /// not carry winter month boundaries, so we use the standard Swiss
    /// convention: winter = October–March.
    private static func effectiveSeason(for date: Date, variable: VariableTariffConfig) -> TariffSeason? {
        if variable.isWinterTimeEnabled == true,
           let winter = variable.winterSeason,
           isWinterMonth(date)
        {
            return winter
        }
        return variable.commonSeason
    }

    private static func isWinterMonth(_ date: Date) -> Bool {
        let month = Calendar.current.component(.month, from: date)
        return month >= 10 || month <= 3  // Oct–Mar
    }

    /// Determine which tariff option applies at the given time based on the schedule
    private static func resolveTariffOption(for date: Date, season: TariffSeason?) -> String {
        guard let season else { return "highTariff" }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        // Get the schedule for the day type
        let slots: [TariffTimeSlot]?
        switch weekday {
        case 1: // Sunday
            slots = season.sunday ?? season.mondayFriday
        case 7: // Saturday
            slots = season.saturday ?? season.mondayFriday
        default: // Monday-Friday
            slots = season.mondayFriday
        }

        guard let slots, !slots.isEmpty else { return "highTariff" }

        let timeString = formatTime(date)

        // Find the last slot whose fromTime <= current time
        var activeOption = slots.first?.tariffOption ?? "highTariff"
        for slot in slots.sorted(by: { $0.fromTime < $1.fromTime }) {
            if slot.fromTime <= timeString {
                activeOption = slot.tariffOption
            } else {
                break
            }
        }

        return activeOption
    }

    /// Map a tariff option name to its price
    private static func priceForOption(_ option: String, prices: TariffPrices) -> Double {
        switch option {
        case "lowTariff": return prices.lowTariff ?? 0
        case "highTariff": return prices.highTariff ?? 0
        case "standardTariff": return prices.standardTariff ?? 0
        case "tariff4": return prices.tariff4 ?? 0
        case "tariff5": return prices.tariff5 ?? 0
        case "tariff6": return prices.tariff6 ?? 0
        default: return prices.highTariff ?? prices.lowTariff ?? 0
        }
    }

    private static func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return String(format: "%02d:%02d", hour, minute)
    }

    // MARK: - V1 Fallbacks

    private static func gridImportCostV1(data: [MainDataItem], tariff: TariffV1Response?) -> Double {
        let rate = (tariff?.highTariff ?? tariff?.singleTariff ?? 0) / 100
        let totalImportWh = data.reduce(0.0) { $0 + $1.importedOverTimeWhatthours }
        return (totalImportWh / 1000) * rate
    }

    private static func gridExportRevenueV1(data: [MainDataItem], tariff: TariffV1Response?) -> Double {
        let rate = (tariff?.directMarketing ?? 0) / 100
        let totalExportWh = data.reduce(0.0) { $0 + $1.exportedOverTimeWhatthours }
        return (totalExportWh / 1000) * rate
    }
}

/// A queryable view over a dynamic / spot tariff time-series. Prices are in
/// main currency units per kWh (e.g. CHF/kWh), already — NOT Rappen/cents.
struct DynamicTariff {
    struct Point {
        let start: Date
        let priceCHF: Double
    }

    /// Ascending by start time.
    let points: [Point]
    /// Length of each price window in seconds.
    let resolution: TimeInterval

    init?(_ response: DynamicTariffResponse?) {
        guard let response, let prices = response.prices, !prices.isEmpty else { return nil }

        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]

        var parsed: [Point] = []
        for entry in prices {
            guard let timeString = entry.time, let price = entry.price else { continue }
            guard let date = withFractional.date(from: timeString) ?? plain.date(from: timeString) else { continue }
            parsed.append(Point(start: date, priceCHF: price))
        }
        guard !parsed.isEmpty else { return nil }

        self.points = parsed.sorted { $0.start < $1.start }
        self.resolution = (response.resolutionMinutes ?? 60) * 60
    }

    /// Price in CHF/kWh covering `date`, or nil if the series doesn't cover it
    /// (so callers can fall back to the static tariff — e.g. for past dates the
    /// dynamic endpoint doesn't return).
    func priceCHF(at date: Date) -> Double? {
        guard let first = points.first, date >= first.start else { return nil }

        var active = first
        var isLast = true
        for (index, point) in points.enumerated() where point.start <= date {
            active = point
            isLast = index == points.count - 1
        }

        // Fully-covered bucket (one with a successor) is always valid; the last
        // bucket is valid only within its resolution window.
        if !isLast { return active.priceCHF }
        return date.timeIntervalSince(active.start) <= resolution ? active.priceCHF : nil
    }
}
