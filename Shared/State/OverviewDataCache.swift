internal import Foundation

/// Best-effort cache of the last successful overview fetch. Read at
/// `CurrentBuildingState.init` to seed the UI with last-known values so
/// the user never sees an empty screen on activation; written after every
/// successful fetch. Decode failures silently clear the key — the server
/// is the source of truth, the cache is just a render hint.
enum OverviewDataCache {
    private static let key = "cached.overview.v1"
    private static let maxAge: TimeInterval = 24 * 3600

    private struct Envelope: Codable {
        let savedAt: Date
        let payload: PersistedOverview
    }

    /// Subset of `OverviewData` safe to persist — just the scalars and
    /// dates the home screen consumes on first render. Device lists and
    /// other `@Observable` nested types are intentionally omitted and will
    /// populate on the first successful fetch (~1–2 s after launch).
    struct PersistedOverview: Codable {
        var currentSolarProduction: Int
        var currentOverallConsumption: Int
        var currentBatteryLevel: Int?
        var currentBatteryChargeRate: Int?
        var currentSolarToGrid: Int
        var currentGridToHouse: Int
        var currentSolarToHouse: Int
        var solarProductionMax: Double
        var lastUpdated: Date?
        var lastSuccessServerFetch: Date?
        var isAnyCarCharing: Bool
        var hasAnyCarChargingStation: Bool
        var hasAnyBattery: Bool
        var todaySelfConsumption: Double?
        var todaySelfConsumptionRate: Double?
        var todayAutarchyDegree: Double?
        var todayProduction: Double?
        var todayConsumption: Double?
    }

    static func load() -> PersistedOverview? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        do {
            let env = try decoder.decode(Envelope.self, from: data)
            guard Date().timeIntervalSince(env.savedAt) < maxAge else {
                return nil
            }
            return env.payload
        } catch {
            // Old schema or corrupted — clear so we don't retry on every launch.
            UserDefaults.standard.removeObject(forKey: key)
            return nil
        }
    }

    static func save(_ overview: OverviewData) {
        let payload = PersistedOverview(
            currentSolarProduction: overview.currentSolarProduction,
            currentOverallConsumption: overview.currentOverallConsumption,
            currentBatteryLevel: overview.currentBatteryLevel,
            currentBatteryChargeRate: overview.currentBatteryChargeRate,
            currentSolarToGrid: overview.currentSolarToGrid,
            currentGridToHouse: overview.currentGridToHouse,
            currentSolarToHouse: overview.currentSolarToHouse,
            solarProductionMax: overview.solarProductionMax,
            lastUpdated: overview.lastUpdated,
            lastSuccessServerFetch: overview.lastSuccessServerFetch,
            isAnyCarCharing: overview.isAnyCarCharing,
            hasAnyCarChargingStation: overview.hasAnyCarChargingStation,
            hasAnyBattery: overview.hasAnyBattery,
            todaySelfConsumption: overview.todaySelfConsumption,
            todaySelfConsumptionRate: overview.todaySelfConsumptionRate,
            todayAutarchyDegree: overview.todayAutarchyDegree,
            todayProduction: overview.todayProduction,
            todayConsumption: overview.todayConsumption
        )
        let env = Envelope(savedAt: Date(), payload: payload)
        if let data = try? encoder.encode(env) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Apply a cached payload onto an `OverviewData` instance. Device lists
    /// are left empty; they'll be overwritten by the first fresh fetch.
    static func apply(_ payload: PersistedOverview, to overview: OverviewData) {
        overview.currentSolarProduction = payload.currentSolarProduction
        overview.currentOverallConsumption = payload.currentOverallConsumption
        overview.currentBatteryLevel = payload.currentBatteryLevel
        overview.currentBatteryChargeRate = payload.currentBatteryChargeRate
        overview.currentSolarToGrid = payload.currentSolarToGrid
        overview.currentGridToHouse = payload.currentGridToHouse
        overview.currentSolarToHouse = payload.currentSolarToHouse
        overview.solarProductionMax = payload.solarProductionMax
        overview.lastUpdated = payload.lastUpdated
        overview.lastSuccessServerFetch = payload.lastSuccessServerFetch
        overview.isAnyCarCharing = payload.isAnyCarCharing
        overview.hasAnyCarChargingStation = payload.hasAnyCarChargingStation
        overview.hasAnyBattery = payload.hasAnyBattery
        overview.todaySelfConsumption = payload.todaySelfConsumption
        overview.todaySelfConsumptionRate = payload.todaySelfConsumptionRate
        overview.todayAutarchyDegree = payload.todayAutarchyDegree
        overview.todayProduction = payload.todayProduction
        overview.todayConsumption = payload.todayConsumption
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
