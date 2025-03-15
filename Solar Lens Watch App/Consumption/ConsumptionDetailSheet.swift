//

import SwiftUI

struct ConsumptionDetailSheet: View {
    var totalCurrentConsumptionInWatt: Int
    var devices: [Device]
    
    var body: some View {
        VStack {
            ConsumptionPieChart(
                totalCurrentConsumptionInWatt: totalCurrentConsumptionInWatt,
                deviceConsumptions: getDeviceConsumptions()
            )
        }
    }
    
    func getDeviceConsumptions() -> [DeviceConsumption] {
        return devices
            .filter({ $0.isConsumingDevice() })
            .map {
                DeviceConsumption.init(
                    id: $0.id,
                    name: $0.name,
                    consumptionInWatt: $0.currentPowerInWatts
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
