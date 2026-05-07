internal import Foundation

/// Phase configuration of the user's wallbox.
///
/// Most domestic wallboxes in CH/DE/AT/DK are fixed 3-phase. Increasingly
/// common: wallboxes that auto-switch between 1- and 3-phase based on
/// load (e.g. go-eCharger, Easee, certain WallBe models). For those we
/// can't pick a fixed W-per-A — we observe it from the wallbox's actual
/// reported power and current setting.
enum WallboxPhases: Int, Codable, CaseIterable, Identifiable {
    case auto = 0
    case one = 1
    case three = 3

    var id: Int { rawValue }

    static let `default`: WallboxPhases = .three

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(Int.self)
        self = WallboxPhases(rawValue: raw) ?? Self.default
    }

    var localizedTitle: LocalizedStringResource {
        switch self {
        case .auto:  return "Auto (1-/3-phase switching)"
        case .one:   return "1-phase (≤ 7.4 kW)"
        case .three: return "3-phase (≤ 22 kW)"
        }
    }

    /// Static W-per-A. For `.auto` this is only used as a fallback when
    /// no live observation is available yet (typically just on the first
    /// tick); we use the 3-phase value because it's pessimistic for the
    /// ramp-UP path (require more export evidence) which is what we want
    /// before we know what the wallbox is actually doing.
    var fallbackWattsPerAmp: Double {
        switch self {
        case .one:   return PowerToAmps.voltageLineToNeutral
        case .three: return PowerToAmps.voltageLineToNeutral * 3
        case .auto:  return PowerToAmps.voltageLineToNeutral * 3
        }
    }
}
