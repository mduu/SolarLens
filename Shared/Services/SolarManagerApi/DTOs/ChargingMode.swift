import AppIntents

enum ChargingMode: Int, Codable, CaseIterable, Identifiable, AppEnum {
    case alwaysCharge = 0
    case withSolarPower = 1
    case withSolarOrLowTariff = 2
    case off = 3
    case constantCurrent = 4
    case minimalAndSolar = 5
    case minimumQuantity = 6
    case chargingTargetSoc = 7

    var id: Int { rawValue }

    static var typeDisplayRepresentation: TypeDisplayRepresentation =
        "Charging Mode"

    static var caseDisplayRepresentations:
        [ChargingMode: DisplayRepresentation] = [
            .withSolarPower: .init(stringLiteral: "Solar only"),
            .withSolarOrLowTariff: .init(stringLiteral: "Solar & Tariff"),
            .alwaysCharge: .init(stringLiteral: "Always"),
            .off: .init(stringLiteral: "Off"),
            .constantCurrent: .init(stringLiteral: "Constant"),
            .minimalAndSolar: .init(stringLiteral: "Minimal & Solar"),
            .minimumQuantity: .init(stringLiteral: "Minimal"),
            .chargingTargetSoc: .init(stringLiteral: "Car %"),
        ]
    
    func isSimpleChargingMode() -> Bool {
        return self == .alwaysCharge
            || self == .withSolarPower
            || self == .withSolarOrLowTariff
            || self == .minimalAndSolar
            || self == .off
    }
}
