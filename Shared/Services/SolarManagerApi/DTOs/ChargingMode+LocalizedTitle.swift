internal import Foundation

extension ChargingMode {
    /// Localized short title for the mode, suitable for inline use in
    /// notification text and UI labels.
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .withSolarPower:       return "Solar only"
        case .withSolarOrLowTariff: return "Solar & Tariff"
        case .alwaysCharge:         return "Always"
        case .off:                  return "Off"
        case .constantCurrent:      return "Constant"
        case .minimalAndSolar:      return "Minimal & Solar"
        case .minimumQuantity:      return "Minimal"
        case .chargingTargetSoc:    return "Car %"
        }
    }
}
