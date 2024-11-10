//
//  OverviewData.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//

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
    @Published var isAnyCarCharing: Bool = false
    @Published var chargingStations: [ChargingStation] = []

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
        isAnyCarCharing: Bool,
        chargingStations: [ChargingStation]
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
        self.isAnyCarCharing = isAnyCarCharing
        self.chargingStations = chargingStations
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
}

class ChargingStation: Observable {
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
