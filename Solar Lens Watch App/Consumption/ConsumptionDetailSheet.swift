//

import SwiftUI

struct ConsumptionDetailSheet: View {
    var totalCurrentConsumptionInWatt: Int
    var devices: [Device]
    
    var body: some View {
        HStack {
            ConsumptionPieChart(
                totalCurrentConsumptionInWatt: totalCurrentConsumptionInWatt,
                deviceConsumptions: getDeviceConsumptions()
            )
        }
    }
    
    func getDeviceConsumptions() -> [DeviceConsumption] {
        return devices
            .filter({ $0.isConsumingDevice() })
            .filter({ $0.hasPower() })
            .map {
                DeviceConsumption.init(
                    id: $0.id,
                    name: $0.name,
                    consumptionInWatt: $0.currentPowerInWatts,
                    color: $0.color
                )
            }
    }
}

#Preview {
    ConsumptionDetailSheet(
        totalCurrentConsumptionInWatt: 5000,
        devices: [
            .init(
                id: "1",
                deviceType: .carCharging,
                name: "Charging",
                priority: 3400,
                color: "#77aaff"
            ),
            .init(
                id: "2",
                deviceType: .energyMeasurement,
                name: "Office",
                priority: 1000,
                color: "#7799ff"
            ),
        ]
    )
}
