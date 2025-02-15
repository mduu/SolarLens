import Foundation
import SwiftUI

class ChargingModeConfiguration: ObservableObject {
    @AppStorage("chargingModesVisibillity") private
        var chargingModeVisibillityData: Data?

    @Published var chargingModeVisibillity: [ChargingMode: Bool] = [
        .alwaysCharge: true,
        .withSolarPower: true,
        .withSolarOrLowTariff: true,
        .off: true,
        .constantCurrent: true,
        .minimalAndSolar: true,
        .minimumQuantity: true,
        .chargingTargetSoc: true,
    ]

    init() {
        decodeData()
    }

    func changeChargingModeVisibillity(mode: ChargingMode, newValue: Bool) {
        chargingModeVisibillity[mode] = newValue
        if let encodedData = try? JSONEncoder().encode(chargingModeVisibillity)
        {
            chargingModeVisibillityData = encodedData
        }
    }

    private func decodeData() {
        if let data = chargingModeVisibillityData,
            let decodedData = try? JSONDecoder().decode(
                [ChargingMode: Bool].self, from: data)
        {
            chargingModeVisibillity = decodedData
        }
    }
}
