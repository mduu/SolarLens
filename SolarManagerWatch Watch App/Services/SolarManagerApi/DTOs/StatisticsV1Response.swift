struct StatisticsV1Response: Codable {
    var consumption: Double?
    var production: Double?
    var selfConsumption: Double?
    var selfConsumptionRate: Double?
    var autarchyDegree: Double?
}
