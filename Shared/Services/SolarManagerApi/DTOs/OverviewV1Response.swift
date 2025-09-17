struct OverviewV1Response: Decodable {
    var plants: Int?
    var supportContracts: Int?
    var production: OverviewV1Production?
    var consumption: OverviewV1Consumption?
    var autarchy: OverviewV1Autarchy?
    var totalEnergy: OverviewV1TotalEnergy?
}

struct OverviewV1Production: Decodable {
    var today: Double?
    var last7Days: Double?
    var thisMonth: Double?
    var thisYear: Double?
}

struct OverviewV1Consumption: Decodable {
    var today: Double?
    var last7Days: Double?
    var thisMonth: Double?
    var thisYear: Double?
    var lastMonth: Double?
    var lastYear: Double?
    var overall: Double?
}

struct OverviewV1Autarchy: Decodable {
    var last24hr: Int
    var lastMonth: Int
    var lastYear: Int
    var overall: Int
}

struct OverviewV1TotalEnergy: Decodable {
    var carChargers: OverviewV1CarChargers?
    var waterHeaters: OverviewV1WaterHeaters?
    var heatpumps: OverviewV1Headpumps?
    var v2xChargers: OverviewV1V2xChargers?
}

struct OverviewV1CarChargers: Decodable {
    var total: Int
    var today: Int
    var last7Days: Int
}

struct OverviewV1WaterHeaters: Decodable {
    var total: Int
    var today: Int
    var last7Days: Int
}

struct OverviewV1Headpumps: Decodable {
    var total: Int
    var today: Int
    var last7Days: Int
}

struct OverviewV1V2xChargers: Decodable {
    var total: Int
    var charged: OverviewV1ChargingInfo
    var discharged: OverviewV1ChargingInfo
}

struct OverviewV1ChargingInfo: Decodable {
    var today: Int
    var last7Days: Int
}
