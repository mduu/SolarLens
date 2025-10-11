internal import Foundation

struct SensorDataV1Response: Decodable {
    /// Timestamp (Time & Date) of the entry
    let date: String // "2024-10-20T19:14:23.193Z"
        
    /// Car-charingg & eneergy-management: Power charging in watts
    let currentPower: Int?
    
    // Battery
    
    /// Battery: Energy discharged from the battery during the interval (in Watt-hours).
    let bdWh: Double?
    
    /// Battery: Energy charged into the battery during the interval (in Watt-hours).
    let bcWh: Double?
    
    /// Battery: Average power discharged from the battery during the interval (in Watts).
    let bdW: Double?
    
    /// Battery: Average power charged into the battery during the interval (in Watts).
    let bcW: Double?
}
