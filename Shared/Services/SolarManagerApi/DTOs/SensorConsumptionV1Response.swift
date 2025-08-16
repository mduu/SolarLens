internal import Foundation

struct SensorConsumptionV1Response : Codable {
    var sensorId: String
    var period: Period
    var data: [SensorConsumptionResponseData] = []
    var totalConsumption: Double
}

struct SensorConsumptionResponseData : Codable {
    var createdAt: String
    var consumption: Double
}
