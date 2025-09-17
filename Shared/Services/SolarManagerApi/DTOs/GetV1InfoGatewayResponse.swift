struct GetV1InfoGatewayResponse : Decodable {
    var gateway: GatewayInfo
    var settings: InfoSettings
}

struct GatewayInfo : Decodable {
    var _id: String
    var signal: String
    var name: String
    var sm_id: String
    var firmware: String?
    var mac: String?
    var ip: String?
    var owner: String?
    var lastErrorDate: String?
    var isInstallationCompleted: Bool
}

struct InfoSettings : Decodable {
    var tariffType: String // "double"
    var lowTariff: Double // 0.288
    var highTariff: Double // 0.322
    var singleTariff: Double? // null
    var currency: String // "CHF/kWh"
    var provider: String?
    var providerType: String?
    var offset_watt: Int
    var kWp: Double
    var houseFuse: Int // example: 25 (kW)
    var loadManagement: Bool
    var price: Double?

    var low_m_f_from: String? // example: 19:01
    var low_m_f_to: String? // example: 06:00
    var low_sat_from: String? // example: 13:00
    var low_sat_to: String? // example: 08:00
    var low_sun_from: String? // example: 00:00
    var low_sun_to: String? // example: 08:00

    var isWinterTimeEnabled: Bool
    var commonSeasons: SeasonsTariffs?
    var winterSeason: SeasonsTariffs?
}

struct SeasonsTariffs : Decodable {
    var mondayFriday: [TariffPeriod]
    var saturday: [TariffPeriod]
    var sunday: [TariffPeriod]
}

struct TariffPeriod : Decodable {
    var from: String // example: 00:00
    var tariff: String // example: "low", "high"
}
