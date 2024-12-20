enum ChargingMode: Int, Codable, CaseIterable, Identifiable {
    case alwaysCharge = 0
    case withSolarPower = 1
    case withSolarOrLowTariff = 2
    case off = 3
    case constantCurrent = 4
    case minimalAndSolar = 5
    case minimumQuantity = 6
    case chargingTargetSoc = 7
    
    var id: Int { rawValue }
}
