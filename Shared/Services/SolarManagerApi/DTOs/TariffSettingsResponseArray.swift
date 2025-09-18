struct TariffSettingsResponseArray : Decodable {
    var purchase: Tariff?
    var feedIn: Tariff?
}

struct Tariff : Decodable {
    var state: TariffState
    var type: TariffItemType
    var tariffType: TariffType?
    var directMarketing: DirectMarketing?
    var country: String
    var user: String?
    var activeSince: String? // Date-Time
    var singleTariff: SingleTariff?
    var variableTariff: VariableTariff?
}

enum TariffState : String, Decodable {
    case active = "active"
    case historic = "historic"
}

enum TariffItemType : String, Decodable {
    case purchase = "purchase"
    case feedIn = "feed-in"
}

enum TariffType : String, Decodable {
    case single = "single"
    case variable = "variable"
    case dynamic = "dynamic"
}

enum DirectMarketing: String, Decodable {
    case standard = "standard"
    case stockExchange = "stockExchange"
    case fixed5Years = "fixed5Years"
    case fixed10Years = "fixed10Years"
}

struct SingleTariff : Decodable {
    var price: Double
}

struct VariableTariff : Decodable {
    var numberOfActiveTariffs: Double?
    var prices: TariffPrice
    var isWinterTimeEnabled: Bool
    var commonSeason: CommonSeason
    var winterSeason: WinterSeason?
}

struct TariffPrice : Decodable {
    var lowTariff: Double
    var highTariff: Double
    var standardTariff: Double?
    var tariff4: Double?
    var tariff5: Double?
    var tariff6: Double?
}
