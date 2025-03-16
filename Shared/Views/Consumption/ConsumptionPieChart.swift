import Charts
import SwiftUI

struct DeviceConsumption: Identifiable {
    var id: String
    var name: String
    var consumptionInWatt: Int
    var color: String?
    var color2: Color {
        return (Color.init(rgbString: color) ?? Color.cyan)
    }

}

struct ConsumptionPieChart: View {
    var totalCurrentConsumptionInWatt: Int
    var deviceConsumptions: [DeviceConsumption]

    let standardColor: [String] = [
        "#AD1457",
        "#8E24AA",
        "#283593",
        "#0097A7",
        "#0D47A1",
        "#00897B",
        "#00695C",
        "#7E57C2",
        "#5C6BC0",
    ]

    var body: some View {
        let allConsumptions: [DeviceConsumption] = getAllConsumptions()

        VStack {

            ZStack {

                Chart(allConsumptions, id: \.id) { device in

                    // Draw filled, semi-transparent sectors
                    SectorMark(
                        angle: .value("Watts", device.consumptionInWatt),
                        innerRadius: .ratio(0.5),
                        outerRadius: .ratio(1),
                        angularInset: 2.0  // Increased inset creates a border effect
                    )
                    .cornerRadius(0)
                    .opacity(0.2)
                    .foregroundStyle(device.color2)
                    .annotation(position: .overlay) {
                        VStack {
                            Text(
                                device.consumptionInWatt
                                    .formatWattsAsKiloWatts()
                            )
                            .font(.system(size: 10))
                            .foregroundColor(device.color2)
                        }
                    }
                }

                Chart(allConsumptions, id: \.id) { device in

                    // Draw the outer ring of the donuts
                    SectorMark(
                        angle: .value("Watts", device.consumptionInWatt),
                        innerRadius: .ratio(0.96),
                        outerRadius: .ratio(1),
                        angularInset: 2.0  // Increased inset creates a border effect
                    )
                    .cornerRadius(5)
                    .opacity(1)
                    .foregroundStyle(device.color2)

                }
                .chartLegend(.visible)
                .chartBackground(alignment: .center) { chart in
                    VStack {
                        Text("Total").foregroundColor(.cyan).bold()
                        Text(
                            totalCurrentConsumptionInWatt.formatWattsAsKiloWatts()
                        )
                    }
                }

            }

            HStack(alignment: .center) {
                FlowLayout(spacing: 3) {

                    ForEach(allConsumptions) { consumption in
                        HStack {
                            Rectangle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(consumption.color2)
                                .cornerRadius(3)
                            Text(consumption.name)
                                .foregroundColor(consumption.color2)
                        }
                    }

                }
            }
            .frame(maxHeight: 20)
            .padding()
            .ignoresSafeArea()
        }

    }

    func getAllConsumptions() -> [DeviceConsumption] {
        let totalConsumptionOfKnownDevices =
            deviceConsumptions
            .reduce(0) {
                $0 + $1.consumptionInWatt
            }

        let otherConsumptionValue =
            totalCurrentConsumptionInWatt - totalConsumptionOfKnownDevices

        var allConsumptions =
            deviceConsumptions

        // Add the rest constumption as "Others"
        if otherConsumptionValue > 0 {
            allConsumptions.append(
                .init(
                    id: "000",
                    name: "Others",
                    consumptionInWatt: otherConsumptionValue,
                    color: "#26C6DA"
                )
            )
        }

        return
            allConsumptions
            .enumerated()
            .map { (index, element) in
                return DeviceConsumption.init(
                    id: element.id,
                    name: element.name,
                    consumptionInWatt: element.consumptionInWatt,
                    color: element.color ?? standardColor[index])  // Apply standard colors if needed
            }

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
                consumptionInWatt: 1200,
                color: "#5599ee"),
        ]
    )
}
