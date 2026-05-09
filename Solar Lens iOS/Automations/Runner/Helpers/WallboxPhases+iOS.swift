internal import Foundation

extension WallboxPhases {
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
