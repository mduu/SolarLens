internal import Foundation

/// Per-wallbox persistence of the user's chosen `WallboxPhases` setting.
/// Keyed by `chargingDeviceId` so each wallbox can have its own phase
/// configuration (auto-switching, fixed 1-phase, fixed 3-phase).
enum WallboxPhasesStore {
    private static let key = "SolarLens.wallboxPhases"

    static func phases(for stationId: String) -> WallboxPhases {
        guard !stationId.isEmpty else { return .default }
        let map = UserDefaults.standard.dictionary(forKey: key)
            as? [String: Int] ?? [:]
        let raw = map[stationId] ?? WallboxPhases.default.rawValue
        return WallboxPhases(rawValue: raw) ?? .default
    }

    static func save(_ phases: WallboxPhases, for stationId: String) {
        guard !stationId.isEmpty else { return }
        var map = UserDefaults.standard.dictionary(forKey: key)
            as? [String: Int] ?? [:]
        map[stationId] = phases.rawValue
        UserDefaults.standard.set(map, forKey: key)
    }
}
