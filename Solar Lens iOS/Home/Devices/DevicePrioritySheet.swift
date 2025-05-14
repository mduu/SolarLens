import SwiftUI

struct DevicePrioritySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState

    @State var isLoading: Bool = false

    var body: some View {
        ZStack {

            VStack(spacing: 0) {

                HStack {
                    Text("Current consumption")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.leading, 20)

                    Spacer()
                }

                ConsumptionPieChart(
                    totalCurrentConsumptionInWatt: buildingState.overviewData
                        .currentOverallConsumption,
                    deviceConsumptions: getDeviceConsumptions(),
                    legendPosition: .right,
                    annotationTextSize: .large
                )

                HStack {
                    Text("Device")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.leading, 20)

                    Spacer()

                    Image(systemName: "arrow.up.arrow.down")
                        .font(.footnote)
                        .padding(.trailing, 20)
                        .foregroundColor(.gray)
                }

                List {

                    ForEach(buildingState.overviewData.devices.sorted(by: { $0.priority < $1.priority })) { device in
                        DevicePriorityRow(device: device)
                            .contentShape(Rectangle())  // Make the whole row tappable
                    }
                    .onMove { indices, newOffset in
                        if let index = indices.first {
                            let device = buildingState.overviewData.devices[
                                index
                            ]

                            Task {
                                isLoading = true

                                let newPriority =
                                    newOffset > index
                                    ? newOffset
                                    : newOffset + 1

                                print(
                                    "Old prio: \(device.priority), new prio: \(newPriority)"
                                )

                                await buildingState.setSensorPriority(
                                    sensorId: device.id,
                                    newPriority: newPriority
                                )

                                isLoading = false
                            }
                        }
                    }
                }
                .listStyle(.inset)
                
                Spacer()

            }
            .navigationTitle("Devices priorities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")  // Use a system icon
                            .resizable()  // Make the image resizable
                            .scaledToFit()  // Fit the image within the available space
                            .frame(width: 18, height: 18)  // Set the size of the image
                            .foregroundColor(.teal)  // Set the color of the image
                    }

                }
            }
            .padding()

            if isLoading {
                ProgressView()
            }
        }
    }

    func getDeviceConsumptions() -> [DeviceConsumption] {
        return buildingState.overviewData.devices
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
    NavigationView {
        DevicePrioritySheet()
            .environment(CurrentBuildingState.fake())
    }
}
