internal import Foundation

struct TariffSettingsV3Response: Codable {
    var purchase: TariffConfig?
    var feedIn: TariffConfig?
}

struct TariffConfig: Codable {
    var state: String?
    var type: String?
    var tariffType: String?
    var directMarketing: String?
    var country: String?
    var singleTariff: SingleTariffConfig?
    var variableTariff: VariableTariffConfig?
    var gridFees: GridFeesConfig?
    var taxesAndDuties: TaxesAndDutiesConfig?
    var activeSince: String?
}

struct SingleTariffConfig: Codable {
    var price: Double?
}

struct VariableTariffConfig: Codable {
    var numberOfActiveTariffs: Int?
    var prices: TariffPrices?
    var commonSeason: TariffSeason?
    var isWinterTimeEnabled: Bool?
    var winterSeason: TariffSeason?
}

struct TariffPrices: Codable {
    var lowTariff: Double?
    var highTariff: Double?
    var standardTariff: Double?
    var tariff4: Double?
    var tariff5: Double?
    var tariff6: Double?
}

struct TariffSeason: Codable {
    var mondayFriday: [TariffTimeSlot]?
    var saturday: [TariffTimeSlot]?
    var sunday: [TariffTimeSlot]?
}

struct TariffTimeSlot: Codable {
    var fromTime: String
    var tariffOption: String
}

struct GridFeesConfig: Codable {
    var fixed: Double?
    var variable: GridFeesVariableConfig?
}

struct GridFeesVariableConfig: Codable {
    var numberOfActiveTariffs: Int?
    var prices: TariffPrices?
    var commonSeason: TariffSeason?
}

struct TaxesAndDutiesConfig: Codable {
    var kWh: Double?
    var month: Double?
}

/// Response of `/v3/users/{smId}/tariff/dynamic` — a time-series of spot /
/// dynamic prices. `price` is in the response's `currency` per kWh (e.g.
/// 0.2976 CHF/kWh), i.e. already in main currency units, NOT Rappen/cents.
struct DynamicTariffResponse: Codable {
    var provider: String?
    var currency: String?
    var resolutionMinutes: Double?
    var prices: [DynamicTariffPrice]?
}

struct DynamicTariffPrice: Codable {
    /// ISO-8601 start time of the price window, e.g. "2024-05-08T17:00:00.000Z".
    var time: String?
    var price: Double?
}
