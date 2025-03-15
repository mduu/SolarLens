import Charts
import SwiftUI

struct DeviceConsumption: Identifiable {
    var id: String
    var name: String
    var consumptionInWatt: Int
    var color: String?
}

struct ConsumptionPieChart: View {
    var totalCurrentConsumptionInWatt: Int
    var deviceConsumptions: [DeviceConsumption]

    var body: some View {
        let allConsumptions: [DeviceConsumption] = getAllConsumptions()

        Chart {

            // Draw filled, semi-transparent sectors
            ForEach(allConsumptions) { device in
                SectorMark(
                    angle: .value("Watts", device.consumptionInWatt),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.0  // Increased inset creates a border effect
                )
                .foregroundStyle(.cyan.opacity(0.4))
            }

        }

    }

    func getAllConsumptions() -> [DeviceConsumption] {
        let allDeviceConsumptions = deviceConsumptions.reduce(0) {
            $0 + $1.consumptionInWatt
        }
        let otherConsumption =
            totalCurrentConsumptionInWatt - allDeviceConsumptions

        var allConsumptions = deviceConsumptions
        if otherConsumption > 0 {
            allConsumptions.append(
                .init(
                    id: "000",
                    name: "Other",
                    consumptionInWatt: otherConsumption,
                    color: "#aaaaaa"
                )
            )
        }

        return allConsumptions
    }
}

#Preview {
    ConsumptionPieChart(
        totalCurrentConsumptionInWatt: 4300,
        deviceConsumptions: [
            .init(
                id: "1",
                name: "Ladestation",
                consumptionInWatt: 2453,
                color: "#00aaff"),
            .init(
                id: "2",
                name: "Arbeitsplatz",
                consumptionInWatt: 120,
                color: "#5599ee"),
        ]
    )
}
