struct EnergyOverview {
    var loaded: Bool = false
    var plants: Int?
    var supportContracts: Int?
    var production: EnergyProduction = .init()
    var consumption: EnergyConsumption = .init()
    var autarchy: EnergyAutarchy = .init()
    var totalEnergy: EnergyTotalEnergy = .init()
}

struct EnergyProduction {
    var today: Double?
    var last7Days: Double?
    var thisMonth: Double?
    var thisYear: Double?
}

struct EnergyConsumption {
    var today: Double?
    var last7Days: Double?
    var thisMonth: Double?
    var thisYear: Double?
    var lastMonth: Double?
    var lastYear: Double?
    var overall: Double?
}

struct EnergyAutarchy {
    var last24hr: Int = 0
    var lastMonth: Int = 0
    var lastYear: Int = 0
    var overall: Int = 0
}

struct EnergyTotalEnergy {
    var carChargers: EnergyCarChargers = .init()
    var waterHeaters: EnergyWaterHeaters = .init()
    var heatpumps: EnergyHeadpumps = .init()
    var v2xChargers: EnergyV2xChargers = .init()
}

struct EnergyCarChargers {
    var total: Int = 0
    var today: Int = 0
    var last7Days: Int = 0
}

struct EnergyWaterHeaters {
    var total: Int = 0
    var today: Int = 0
    var last7Days: Int = 0
}

struct EnergyHeadpumps {
    var total: Int = 0
    var today: Int = 0
    var last7Days: Int = 0
}

struct EnergyV2xChargers {
    var total: Int = 0
    var charged: EnergyChargingInfo = .init()
    var discharged: EnergyChargingInfo = .init()
}

struct EnergyChargingInfo {
    var today: Int = 0
    var last7Days: Int = 0
}
