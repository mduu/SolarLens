import Foundation

class OverviewData: ObservableObject {
    private let minGridConsumptionTreashold: Int = 100
    private let minGridIngestionTreashold: Int = 100

    @Published var currentSolarProduction: Int = 0
    @Published var currentOverallConsumption: Int = 0
    @Published var currentBatteryLevel: Int? = 0
    @Published var currentBatteryChargeRate: Int? = 0
    @Published var currentSolarToGrid: Int = 0
    @Published var currentGridToHouse: Int = 0
    @Published var currentSolarToHouse: Int = 0
    @Published var solarProductionMax: Double = 0
    @Published var hasConnectionError: Bool = false
    @Published var lastUpdated: Date? = nil
    @Published var lastSuccessServerFetch: Date? = nil
    @Published var isAnyCarCharing: Bool = false
    @Published var chargingStations: [ChargingStation] = []
    @Published var isStaleData: Bool = false
    @Published var hasAnyCarChargingStation: Bool = true
    @Published var todaySelfConsumption: Double? = nil
    @Published var todaySelfConsumptionRate: Double? = nil
    @Published var todayProduction: Double? = nil
    @Published var todayConsumption: Double? = nil

    static func empty() -> OverviewData {
        OverviewData(
            currentSolarProduction: 0,
            currentOverallConsumption: 0,
            currentBatteryLevel: nil,
            currentBatteryChargeRate: nil,
            currentSolarToGrid: 0,
            currentGridToHouse: 0,
            currentSolarToHouse: 0,
            solarProductionMax: 0,
            hasConnectionError: true,
            lastUpdated: Date(),
            lastSuccessServerFetch: Date(),
            isAnyCarCharing: false,
            chargingStations: [],
            todaySelfConsumption: nil,
            todaySelfConsumptionRate: nil,
            todayProduction: nil,
            todayConsumption: nil
        )
    }

    static func fake() -> OverviewData {
        .init(
            currentSolarProduction: 4550,
            currentOverallConsumption: 1200,
            currentBatteryLevel: 78,
            currentBatteryChargeRate: 3400,
            currentSolarToGrid: 10,
            currentGridToHouse: 0,
            currentSolarToHouse: 1200,
            solarProductionMax: 11000,
            hasConnectionError: false,
            lastUpdated: Date(),
            lastSuccessServerFetch: Date(),
            isAnyCarCharing: true,
            chargingStations: [
                .init(
                    id: "42",
                    name: "Keba 1",
                    chargingMode: ChargingMode.withSolarPower,
                    priority: 0,
                    currentPower: 0,
                    signal: SensorConnectionStatus.connected),
                .init(
                    id: "43",
                    name: "Keba 2",
                    chargingMode: ChargingMode.withSolarPower,
                    priority: 1,
                    currentPower: 11356,
                    signal: SensorConnectionStatus.connected),
                .init(
                    id: "44",
                    name: "Keba 3",
                    chargingMode: ChargingMode.withSolarPower,
                    priority: 2,
                    currentPower: 0,
                    signal: SensorConnectionStatus.connected),
            ]
        )
    }

    init() {
    }

    init(
        currentSolarProduction: Int,
        currentOverallConsumption: Int,
        currentBatteryLevel: Int?,
        currentBatteryChargeRate: Int?,
        currentSolarToGrid: Int,
        currentGridToHouse: Int,
        currentSolarToHouse: Int,
        solarProductionMax: Double,
        hasConnectionError: Bool,
        lastUpdated: Date?,
        lastSuccessServerFetch: Date?,
        isAnyCarCharing: Bool,
        chargingStations: [ChargingStation],
        todaySelfConsumption: Double? = nil,
        todaySelfConsumptionRate: Double? = nil,
        todayProduction: Double? = nil,
        todayConsumption: Double? = nil
    ) {
        self.currentSolarProduction = currentSolarProduction
        self.currentOverallConsumption = currentOverallConsumption
        self.currentBatteryLevel = currentBatteryLevel
        self.currentBatteryChargeRate = currentBatteryChargeRate
        self.currentSolarToGrid = currentSolarToGrid
        self.currentGridToHouse = currentGridToHouse
        self.currentSolarToHouse = currentSolarToHouse
        self.solarProductionMax = solarProductionMax
        self.hasConnectionError = hasConnectionError
        self.lastUpdated = lastUpdated
        self.lastSuccessServerFetch = lastSuccessServerFetch
        self.isAnyCarCharing = isAnyCarCharing
        self.chargingStations = chargingStations
        self.isStaleData = getIsStaleData()
        self.hasAnyCarChargingStation = chargingStations.count > 0
        self.todaySelfConsumption = todaySelfConsumption
        self.todaySelfConsumptionRate = todaySelfConsumptionRate
        self.todayProduction = todayProduction
        self.todayConsumption = todayConsumption
    }

    func isFlowBatteryToHome() -> Bool {
        return currentBatteryChargeRate ?? 0 <= -100
    }

    func isFlowSolarToBattery() -> Bool {
        return currentBatteryChargeRate ?? 0 >= 100
    }

    func isFlowSolarToHouse() -> Bool {
        return currentSolarToHouse >= 100
    }

    func isFlowSolarToGrid() -> Bool {
        return currentSolarToGrid >= minGridIngestionTreashold
    }

    func isFlowGridToHouse() -> Bool {
        return currentGridToHouse >= minGridConsumptionTreashold
    }

    /**
     Return <code>true</code> if the fetched server-data is outdated.
     This indicates a server-side issue in Solar Manager backend.
     */
    private func getIsStaleData() -> Bool {
        guard let lastFetch = lastSuccessServerFetch,
            let lastUpdate = lastUpdated
        else {
            if lastSuccessServerFetch == nil {
                return false
            }

            if lastUpdated == nil {
                return true
            }

            return false
        }

        return lastFetch.timeIntervalSince(lastUpdate) > 30 * 60
    }
}

class ChargingStation: Observable, Identifiable {
    @Published var id: String
    @Published var name: String
    @Published var chargingMode: ChargingMode
    @Published var priority: Int  // lower number is higher Priority (ordering)
    @Published var currentPower: Int  // Watt
    @Published var signal: SensorConnectionStatus?

    init(
        id: String, name: String, chargingMode: ChargingMode, priority: Int,
        currentPower: Int, signal: SensorConnectionStatus? = nil
    ) {
        self.id = id
        self.name = name
        self.chargingMode = chargingMode
        self.priority = priority
        self.currentPower = currentPower
        self.signal = signal
    }
}
