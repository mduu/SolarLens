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
            Chart(allConsumptions, id: \.id) { device in
                SectorMark(
                    angle: .value("Watts", device.consumptionInWatt),
                    innerRadius: .ratio(0.75),
                    outerRadius: .ratio(0.92),
                    angularInset: 2
                )
                .cornerRadius(5)
                .foregroundStyle(device.color2)
            }
            .chartLegend(.hidden)
            .chartBackground(alignment: .center) { _ in
                VStack(spacing: 1) {
                    if let overrideLabelText, let overrideValue {
                        Text(overrideLabelText)
                            .font(.system(size: annotationTextSize == .small ? 11 : 14, weight: .semibold))
                            .foregroundColor(overrideLabelColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(overrideValue)
                            .font(.system(size: annotationTextSize == .small ? 11 : 14))
                    } else {
                        Text("Total")
                            .font(.system(size: annotationTextSize == .small ? 11 : 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(
                            totalCurrentConsumptionInWatt
                                .formatWattsAsKiloWatts()
                        )
                        .font(.system(size: annotationTextSize == .small ? 11 : 14))
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)

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
                            #if !os(tvOS)

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
                                                    self.overrideLabelColor =
                                                        nil
                                                    self.overrideValue = nil

                                                    print(
                                                        "long press ended on \(consumption.name)"
                                                    )
                                                }
                                            }
                                        }
                                )
                            #endif
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
                        #if !os(tvOS)

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
                        #endif
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
                    id: "others_\(UUID().uuidString)",
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
                // Ensure unique IDs by using index as fallback
                let uniqueId = element.id.isEmpty ? "device_\(index)_\(UUID().uuidString)" : element.id
                return DeviceConsumption.init(
                    id: uniqueId,
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
