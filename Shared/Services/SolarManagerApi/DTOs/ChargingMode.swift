import AppIntents

enum ChargingMode: Int, Codable, CaseIterable, Identifiable, AppEnum, Sendable {
    case alwaysCharge = 0
    case withSolarPower = 1
    case withSolarOrLowTariff = 2
    case off = 3
    case constantCurrent = 4
    case minimalAndSolar = 5
    case minimumQuantity = 6
    case chargingTargetSoc = 7
    /// Solar Manager's "Aria" optimization (API 1.91+). Solar Lens shows it
    /// when a charger is in this mode but does not offer it for selection yet,
    /// so it is left out of `allCases`.
    case aria = 8

    /// Modes the user can pick. Excludes `.aria`, which is display-only.
    static let allCases: [ChargingMode] = [
        .alwaysCharge, .withSolarPower, .withSolarOrLowTariff, .off,
        .constantCurrent, .minimalAndSolar, .minimumQuantity, .chargingTargetSoc,
    ]

    var id: Int { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        self = ChargingMode(rawValue: rawValue) ?? .off
    }

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
            .aria: .init(stringLiteral: "Aria"),
        ]
    
    func isSimpleChargingMode() -> Bool {
        return self == .alwaysCharge
            || self == .withSolarPower
            || self == .withSolarOrLowTariff
            || self == .minimalAndSolar
            || self == .off
    }
}
