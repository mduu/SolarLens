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

enum LegendPosition {
    case bottom
    case right
}

enum AnnotationTextSize {
    case small
    case large
}

struct ConsumptionPieChart: View {
    var totalCurrentConsumptionInWatt: Int
    var deviceConsumptions: [DeviceConsumption]
    var legendPosition: LegendPosition = .bottom
    var annotationTextSize: AnnotationTextSize = .small

    @State var overrideLabelText: String?
    @State var overrideLabelColor: Color?
    @State var overrideValue: String?

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

        HVStack(isVertical: legendPosition == .bottom) {
            ZStack {

                Chart(allConsumptions, id: \.id) { device in

                    // Draw filled, semi-transparent sectors
                    SectorMark(
                        angle: .value("Watts", device.consumptionInWatt),
                        innerRadius: .ratio(0.6),
                        outerRadius: .ratio(1),
                        angularInset: 2.0  // Increased inset creates a border effect
                    )
                    .cornerRadius(0)
                    .opacity(0.3)
                    .foregroundStyle(device.color2)
                    .annotation(position: .overlay) {
                        Group {
                            if device.consumptionInWatt > 20 {
                                Text(
                                    device.consumptionInWatt
                                        .formatWattsAsKiloWatts()
                                )
                                .font(
                                    .system(
                                        size: annotationTextSize == .small
                                            ? 10 : 14
                                    )
                                )
                                .foregroundColor(device.color2)
                            }
                        }
                    }
                }

                Chart(allConsumptions, id: \.id) { device in

                    // Draw the outer ring of the donuts
                    SectorMark(
                        angle: .value("Watts", device.consumptionInWatt),
                        innerRadius: .ratio(0.95),
                        outerRadius: .ratio(0.61),
                        angularInset: 2.0  // Increased inset creates a border effect
                    )
                    .cornerRadius(0)
                    .opacity(1)
                    .foregroundStyle(device.color2)

                }
                .chartLegend(.visible)
                .chartBackground(alignment: .center) { chart in
                    VStack {
                        if overrideLabelText != nil && overrideValue != nil {
                            Text(overrideLabelText!)
                                .foregroundColor(overrideLabelColor)
                                .bold()
                            Text(overrideValue!)
                        } else {

                            Text("Total").foregroundColor(.cyan).bold()
                            Text(
                                totalCurrentConsumptionInWatt
                                    .formatWattsAsKiloWatts()
                            )

                        }
                    }
                }
            }  // :ZStack

            if legendPosition == .bottom {
                ScrollView {

                    FlowLayout(spacing: 5) {

                        ForEach(allConsumptions) { consumption in
                            HStack {
                                Rectangle()
                                    .frame(width: 10, height: 10)
                                    .foregroundColor(consumption.color2)
                                    .cornerRadius(2)
                                Text(consumption.name)
                                    .foregroundColor(consumption.color2)
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)  // Detect press and release
                                    .onChanged { _ in
                                        DispatchQueue.global().async {

                                            self.overrideLabelText =
                                                consumption.name
                                            self.overrideLabelColor =
                                                consumption.color2
                                            self.overrideValue = consumption
                                                .consumptionInWatt
                                                .formatWattsAsWattsKiloWatts(
                                                    widthUnit: true
                                                )

                                            print(
                                                "long press start on \(consumption.name), value: \(String(describing: overrideValue))"
                                            )
                                        }
                                    }
                                    .onEnded { _ in

                                        if self.overrideLabelText != nil {
                                            DispatchQueue.global().async {

                                                self.overrideLabelText = nil
                                                self.overrideLabelColor = nil
                                                self.overrideValue = nil

                                                print(
                                                    "long press ended on \(consumption.name)"
                                                )
                                            }
                                        }
                                    }
                            )
                        }

                    }  // :FlowLayout

                }  // :ScrollView
                .frame(maxHeight: 60)
                .padding(.horizontal, 20)
            } else {
                FlowLayout(spacing: 5) {

                    ForEach(allConsumptions) { consumption in
                        HStack {
                            Rectangle()
                                .frame(width: 10, height: 10)
                                .foregroundColor(consumption.color2)
                                .cornerRadius(2)
                            Text(consumption.name)
                                .foregroundColor(consumption.color2)
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)  // Detect press and release
                                .onChanged { _ in
                                    DispatchQueue.global().async {

                                        self.overrideLabelText =
                                            consumption.name
                                        self.overrideLabelColor =
                                            consumption.color2
                                        self.overrideValue = consumption
                                            .consumptionInWatt
                                            .formatWattsAsWattsKiloWatts(
                                                widthUnit: true
                                            )

                                        print(
                                            "long press start on \(consumption.name), value: \(overrideValue ?? "")"
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    DispatchQueue.global().async {

                                        self.overrideLabelText = nil
                                        self.overrideLabelColor = nil
                                        self.overrideValue = nil

                                        print(
                                            "long press ended on \(consumption.name)"
                                        )
                                    }
                                }
                        )
                    }

                }  // :FlowLayout
                .padding(.leading)
            }

        }  // :HVStack
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
                    color: element.color ?? standardColor[index]
                )  // Apply standard colors if needed
            }

    }
}

#Preview("Normal") {

    VStack {

        ConsumptionPieChart(
            totalCurrentConsumptionInWatt: 4300,
            deviceConsumptions: [
                .init(
                    id: "1",
                    name: "Ladestation",
                    consumptionInWatt: 2453,
                    color: "#00aaff"
                ),
                .init(
                    id: "2",
                    name: "Arbeitsplatz",
                    consumptionInWatt: 1200,
                    color: "#5599ee"
                ),
            ],
            legendPosition: .bottom
        )
        .background(.black)
        .frame(maxWidth: 200, maxHeight: 200)

        ConsumptionPieChart(
            totalCurrentConsumptionInWatt: 4300,
            deviceConsumptions: [
                .init(
                    id: "1",
                    name: "Ladestation",
                    consumptionInWatt: 2453,
                    color: "#00aaff"
                ),
                .init(
                    id: "2",
                    name: "Arbeitsplatz",
                    consumptionInWatt: 1200,
                    color: "#5599ee"
                ),
            ],
            legendPosition: .right,
            annotationTextSize: .large
        )

        Spacer()
    }
    .padding(.top, 100)
}
