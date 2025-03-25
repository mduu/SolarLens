import SwiftUI

@Observable
class OverviewData {
    private let minGridConsumptionTreashold: Int = 100
    private let minGridIngestionTreashold: Int = 100

    var currentSolarProduction: Int = 0
    var currentOverallConsumption: Int = 0
    var currentBatteryLevel: Int? = 0
    var currentBatteryChargeRate: Int? = 0
    var currentSolarToGrid: Int = 0
    var currentGridToHouse: Int = 0
    var currentSolarToHouse: Int = 0
    var solarProductionMax: Double = 0
    var hasConnectionError: Bool = false
    var lastUpdated: Date? = nil
    var lastSuccessServerFetch: Date? = nil
    var isAnyCarCharing: Bool = false
    var chargingStations: [ChargingStation] = []
    var devices: [Device] = []
    var isStaleData: Bool = false
    var hasAnyCarChargingStation: Bool = true
    var todaySelfConsumption: Double? = nil
    var todaySelfConsumptionRate: Double? = nil
    var todayAutarchyDegree: Double? = nil
    var todayProduction: Double? = nil
    var todayConsumption: Double? = nil
    var todayGridImported: Double? = nil
    var todayGridExported: Double? = nil
    var todayBatteryCharged: Double? = nil

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
            devices: [],
            todaySelfConsumption: nil,
            todaySelfConsumptionRate: nil,
            todayAutarchyDegree: nil,
            todayProduction: nil,
            todayConsumption: nil,
            todayGridImported: nil,
            todayGridExported: nil,
            todayBatteryCharged: nil
        )
    }

    static func fake(batteryToHouse: Bool = false) -> OverviewData {
        .init(
            currentSolarProduction: 4550,
            currentOverallConsumption: 1200,
            currentBatteryLevel: 78,
            currentBatteryChargeRate: batteryToHouse ? -4301 : 3400,
            currentSolarToGrid: 500,
            currentGridToHouse: 600,
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
                    priority: 1,
                    currentPower: 11356,
                    signal: SensorConnectionStatus.connected),
                .init(
                    id: "43",
                    name: "Keba 2",
                    chargingMode: ChargingMode.withSolarPower,
                    priority: 2,
                    currentPower: 0,
                    signal: SensorConnectionStatus.connected),
                .init(
                    id: "44",
                    name: "Keba 3",
                    chargingMode: ChargingMode.withSolarPower,
                    priority: 3,
                    currentPower: 0,
                    signal: SensorConnectionStatus.connected),
            ],
            devices: [
                Device.init(
                    id: "42",
                    deviceType: .carCharging,
                    name: "Keba 1",
                    priority: 1,
                    currentPowerInWatts: 11356,
                    color: "#ff00ff",
                    signal: SensorConnectionStatus.connected,
                    hasError: false),
                Device.init(
                    id: "43",
                    deviceType: .carCharging,
                    name: "Keba 2",
                    priority: 3,
                    currentPowerInWatts: 0,
                    color: "#ff00af",
                    signal: SensorConnectionStatus.connected,
                    hasError: false),
                Device.init(
                    id: "44",
                    deviceType: .carCharging,
                    name: "Keba 3",
                    priority: 4,
                    currentPowerInWatts: 0,
                    color: "#ff000f",
                    signal: SensorConnectionStatus.notConnected,
                    hasError: true),
                Device.init(
                    id: "10",
                    deviceType: .battery,
                    name: "Main Bat.",
                    priority: 2,
                    currentPowerInWatts: 0,
                    color: "#ffff06",
                    signal: SensorConnectionStatus.connected,
                    hasError: false),
                Device.init(
                    id: "20",
                    deviceType: .energyMeasurement,
                    name: "Home-Office",
                    priority: 5,
                    currentPowerInWatts: 12,
                    color: "#aaff06",
                    signal: SensorConnectionStatus.connected,
                    hasError: false)
            ],
            todaySelfConsumption: 4340,
            todaySelfConsumptionRate: 89,
            todayAutarchyDegree: 93,
            todayProduction: 23393,
            todayConsumption: 4300,
            todayGridImported: 25403,
            todayGridExported: 28838,
            todayBatteryCharged: 23480
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
        devices: [Device],
        todaySelfConsumption: Double? = nil,
        todaySelfConsumptionRate: Double? = nil,
        todayAutarchyDegree: Double? = nil,
        todayProduction: Double? = nil,
        todayConsumption: Double? = nil,
        todayGridImported: Double? = nil,
        todayGridExported: Double? = nil,
        todayBatteryCharged: Double? = nil
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
        self.devices = devices
        self.isStaleData = getIsStaleData()
        self.hasAnyCarChargingStation = chargingStations.count > 0
        self.todaySelfConsumption = todaySelfConsumption
        self.todaySelfConsumptionRate = todaySelfConsumptionRate
        self.todayAutarchyDegree = todayAutarchyDegree
        self.todayProduction = todayProduction
        self.todayConsumption = todayConsumption
        self.todayGridImported = todayGridImported
        self.todayGridExported = todayGridExported
        self.todayBatteryCharged = todayBatteryCharged
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

@Observable
class ChargingStation: Identifiable {
    var id: String
    var name: String
    var chargingMode: ChargingMode
    var priority: Int  // lower number is higher Priority (ordering)
    var currentPower: Int  // Watt
    var signal: SensorConnectionStatus?

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

@Observable
class Device: Identifiable {
    var id: String
    var deviceType: DeviceType = .other
    var name: String = ""
    var priority: Int
    var currentPowerInWatts: Int = 0
    var color: String?
    var signal: SensorConnectionStatus
    var hasError: Bool = false

    init(
        id: String,
        deviceType: DeviceType,
        name: String = "",
        priority: Int,
        currentPowerInWatts: Int = 0,
        color: String? = nil,
        signal: SensorConnectionStatus = .connected,
        hasError: Bool = false
    ) {
        self.id = id
        self.deviceType = deviceType
        self.name = name
        self.priority = priority
        self.currentPowerInWatts = currentPowerInWatts
        self.color = color
        self.signal = signal
        self.hasError = hasError
    }
    
    func hasPower() -> Bool {
        return currentPowerInWatts > 10 || currentPowerInWatts < -10
    }
    
    func isConsumingDevice() -> Bool {
        return deviceType != .battery
    }
}

extension Device {

    static func mapStringToDeviceType(stringValue: String?) -> DeviceType {
        guard let value = stringValue?.lowercased() else {
            return .other
        }

        switch value {
        case "energy measurement":
            return .energyMeasurement
        case "battery":
            return .battery
        case "car charging":
            return .carCharging
        default:
            return .other
        }
    }

}

public enum DeviceType {
    case carCharging
    case battery
    case energyMeasurement
    case other
}
