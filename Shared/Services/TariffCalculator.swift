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
            let ratePerKwh = resolveRate(for: item.date, config: config) / 100
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

    /// Calculate battery net savings in main currency units
    /// Discharge savings (avoided import) minus charge cost (lost export)
    static func batterySavings(
        data: [MainDataItem],
        tariffSettings: TariffSettingsV3Response?,
        fallbackTariff: TariffV1Response?
    ) -> Double {
        let dischargeSavings: Double
        let chargeCost: Double

        if let purchaseConfig = tariffSettings?.purchase,
           let feedInConfig = tariffSettings?.feedIn
        {
            dischargeSavings = data.reduce(0.0) { total, item in
                let rate = resolveRate(for: item.date, config: purchaseConfig) / 100
                return total + (item.batteryDischargedWh / 1000) * rate
            }
            chargeCost = data.reduce(0.0) { total, item in
                let rate = resolveRate(for: item.date, config: feedInConfig) / 100
                return total + (item.batteryChargedWh / 1000) * rate
            }
        } else {
            let importRate = (fallbackTariff?.highTariff ?? fallbackTariff?.singleTariff ?? 0) / 100
            let exportRate = (fallbackTariff?.directMarketing ?? 0) / 100
            let totalDischarged = data.reduce(0.0) { $0 + $1.batteryDischargedWh }
            let totalCharged = data.reduce(0.0) { $0 + $1.batteryChargedWh }
            dischargeSavings = (totalDischarged / 1000) * importRate
            chargeCost = (totalCharged / 1000) * exportRate
        }

        return dischargeSavings - chargeCost
    }

    // MARK: - Rate Resolution

    /// Resolve the applicable tariff rate (in cents/Rappen per kWh) for a given timestamp
    static func resolveRate(for date: Date, config: TariffConfig) -> Double {
        switch config.tariffType {
        case "single":
            return config.singleTariff?.price ?? 0

        case "variable":
            guard let variable = config.variableTariff,
                  let prices = variable.prices
            else { return 0 }

            let option = resolveTariffOption(for: date, season: variable.commonSeason)
            return priceForOption(option, prices: prices)

        default:
            return config.singleTariff?.price ?? 0
        }
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
