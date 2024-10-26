//
//  ChargingMode.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 25.10.2024.
//

enum ChargingMode: Int, Codable, CaseIterable {
    case alwaysCharge = 0
    case withSolarPower = 1
    case withSolarOrLowTariff = 2
    case off = 3
    case constantCurrent = 4
    case minimalAndSolar = 5
    case minimumQuantity = 6
    case chargingTargetSoc = 7
}
