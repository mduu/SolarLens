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

    /// Full, unabbreviated title for contexts with room for the whole name —
    /// e.g. CarPlay list rows, where `localizedTitle`'s abbreviations
    /// ("Solar & Tarifopt.") would needlessly truncate.
    var localizedTitleLong: LocalizedStringResource {
        switch self {
        case .withSolarPower:       return "Solar only"
        case .withSolarOrLowTariff: return "Solar & tariff-optimized"
        case .alwaysCharge:         return "Always charge"
        case .off:                  return "Off"
        case .constantCurrent:      return "Constant current"
        case .minimalAndSolar:      return "Minimal & Solar"
        case .minimumQuantity:      return "Minimum quantity"
        case .chargingTargetSoc:    return "Target charge level"
        }
    }
}
