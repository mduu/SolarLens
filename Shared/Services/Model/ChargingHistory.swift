internal import Foundation

/// One sample of a charging station's history.
struct ChargingHistoryPoint: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    /// Average charging power during the interval, in watts.
    let powerW: Double
    /// Energy delivered during the interval, in watt-hours.
    let energyWh: Double
}

/// What one charging station delivered over a stretch of time.
struct ChargingHistory: Identifiable, Sendable {
    var id: String { stationId }
    let stationId: String
    let points: [ChargingHistoryPoint]
}
