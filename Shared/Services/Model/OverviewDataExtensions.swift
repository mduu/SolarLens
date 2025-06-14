import Foundation

extension OverviewData {
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
            todayBatteryCharged: nil,
            cars: []
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
                    signal: SensorConnectionStatus.connected
                ),
                .init(
                    id: "43",
                    name: "Keba 2",
                    chargingMode: ChargingMode.withSolarPower,
                    priority: 2,
                    currentPower: 0,
                    signal: SensorConnectionStatus.connected
                ),
                .init(
                    id: "44",
                    name: "Keba 3",
                    chargingMode: ChargingMode.withSolarPower,
                    priority: 3,
                    currentPower: 0,
                    signal: SensorConnectionStatus.connected
                ),
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
                    hasError: false
                ),
                Device.init(
                    id: "43",
                    deviceType: .carCharging,
                    name: "Keba 2",
                    priority: 3,
                    currentPowerInWatts: 0,
                    color: "#ff00af",
                    signal: SensorConnectionStatus.connected,
                    hasError: false
                ),
                Device.init(
                    id: "44",
                    deviceType: .carCharging,
                    name: "Keba 3",
                    priority: 4,
                    currentPowerInWatts: 0,
                    color: "#ff000f",
                    signal: SensorConnectionStatus.notConnected,
                    hasError: true
                ),
                Device.init(
                    id: "10",
                    deviceType: .battery,
                    name: "Main Bat.",
                    priority: 2,
                    currentPowerInWatts: 0,
                    color: "#ffff06",
                    signal: SensorConnectionStatus.connected,
                    hasError: false
                ),
                Device.init(
                    id: "20",
                    deviceType: .energyMeasurement,
                    name: "Home-Office",
                    priority: 5,
                    currentPowerInWatts: 12,
                    color: "#aaff06",
                    signal: SensorConnectionStatus.connected,
                    hasError: false
                ),
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

    static func fakeWithBattery(battery: Device = Device.fakeBattery()) -> OverviewData {
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
            isAnyCarCharing: false,
            chargingStations: [
                .init(
                    id: "42",
                    name: "Keba",
                    chargingMode: ChargingMode.withSolarPower,
                    priority: 1,
                    currentPower: 0,
                    signal: SensorConnectionStatus.connected
                )
            ],
            devices: [
                battery
            ],
            todayAutarchyDegree: 78
        )
    }
}
