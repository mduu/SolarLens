internal import Foundation

/// Per-charging-station persistence of the user's chosen
/// `ChargingStationPhases` setting. Keyed by `chargingDeviceId` so each
/// charging station can have its own phase configuration
/// (auto-switching, fixed 1-phase, fixed 3-phase).
enum ChargingStationPhasesStore {
    private static let key = "SolarLens.chargingStationPhases"

    static func phases(for stationId: String) -> ChargingStationPhases {
        guard !stationId.isEmpty else { return .default }
        let map = UserDefaults.standard.dictionary(forKey: key)
            as? [String: Int] ?? [:]
        let raw = map[stationId] ?? ChargingStationPhases.default.rawValue
        return ChargingStationPhases(rawValue: raw) ?? .default
    }

    static func save(_ phases: ChargingStationPhases, for stationId: String) {
        guard !stationId.isEmpty else { return }
        var map = UserDefaults.standard.dictionary(forKey: key)
            as? [String: Int] ?? [:]
        map[stationId] = phases.rawValue
        UserDefaults.standard.set(map, forKey: key)
    }
}
