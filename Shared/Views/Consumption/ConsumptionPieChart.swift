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

        Chart(allConsumptions, id: \.id) { device in

            // Draw filled, semi-transparent sectors
            SectorMark(
                angle: .value("Watts", device.consumptionInWatt),
                innerRadius: .ratio(0.5),
                angularInset: 2.0  // Increased inset creates a border effect
            )
            .cornerRadius(5)
            .annotation(position: .overlay) {
                Text("\(Int(device.consumptionInWatt))W")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .foregroundStyle(
                (Color.init(rgbString: device.color) ?? Color.cyan).opacity(0.7)
            )

        }
        .chartLegend(.visible)

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
