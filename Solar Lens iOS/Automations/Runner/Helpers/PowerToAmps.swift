internal import Foundation

enum PowerToAmps {
    static let minAmps = 6
    static let maxAmps = 32
    static let voltageLineToLine = 400.0
    static let voltageLineToNeutral = 230.0

    /// Convert a power budget (W) into a charging station `constantCurrentSetting` in
    /// amps, clamped to the protocol-allowed 6–32 A range.
    ///
    /// - Parameters:
    ///   - powerW: power budget in Watts (e.g. summed `maxDischargePower`).
    ///   - phases: 1 or 3. Default 3 — covers typical CH/DE/AT/DK domestic
    ///     charging stations (11 kW @ 16 A or 22 kW @ 32 A on 400 V).
    ///
    /// Floor (rather than round) so the initial setting is strictly under
    /// the stated capacity; the monitoring loop ramps up from there.
    static func convert(powerW: Int, phases: Int = 3) -> Int {
        let amps: Double
        switch phases {
        case 3:
            amps = Double(powerW) / (sqrt(3.0) * voltageLineToLine)
        default:
            amps = Double(powerW) / voltageLineToNeutral
        }
        return max(minAmps, min(maxAmps, Int(floor(amps))))
    }
}
