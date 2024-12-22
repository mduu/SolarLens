struct GatewayIntervalConsumption : Codable {
    /// example: 00000000F1584HB3
    var smId: String
    
    /// example: 2022-06-01T00:00:00.000Z
    var from: String
    
    /// example: 2022-06-10T00:00:00.000Z
    var to: String
    
    /// Interval in seconds (currently only 300 is supported)
    var interval: Int = 300
    
    var data: [GatewayIntervalConsumptionData] = []
}

struct GatewayIntervalConsumptionData : Codable {
    /// example: 2022-06-01T00:00:00.000Z
    var date: String
    
    /// example: 1000
    var cW: Double
    
    /// example: 0
    var pW: Double
}
