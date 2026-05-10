internal import Foundation

/// Phase configuration of the user's charging station.
///
/// Most domestic charging stations in CH/DE/AT/DK are fixed 3-phase.
/// Increasingly common: charging stations that auto-switch between 1-
/// and 3-phase based on load (e.g. go-eCharger, Easee, certain WallBe
/// models). For those we can't pick a fixed W-per-A — we observe it
/// from the charging station's actual reported power and current
/// setting.
enum ChargingStationPhases: Int, Codable, CaseIterable, Identifiable, Sendable {
    case auto = 0
    case one = 1
    case three = 3

    var id: Int { rawValue }

    static let `default`: ChargingStationPhases = .three

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(Int.self)
        self = ChargingStationPhases(rawValue: raw) ?? Self.default
    }

    var localizedTitle: LocalizedStringResource {
        switch self {
        case .auto:  return "Auto (1-/3-phase switching)"
        case .one:   return "1-phase (≤ 7.4 kW)"
        case .three: return "3-phase (≤ 22 kW)"
        }
    }
}
