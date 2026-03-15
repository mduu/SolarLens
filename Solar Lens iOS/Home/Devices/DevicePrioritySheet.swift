import SwiftUI

struct DevicePrioritySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState

    @State var isLoading: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.05, green: 0.08, blue: 0.1), Color(red: 0.05, green: 0.05, blue: 0.05)]
                    : [Color(red: 0.94, green: 0.97, blue: 0.99), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Pie chart card
                VStack(spacing: 8) {
                    ConsumptionPieChart(
                        totalCurrentConsumptionInWatt: buildingState.overviewData
                            .currentOverallConsumption,
                        deviceConsumptions: getDeviceConsumptions(),
                        legendPosition: .right,
                        annotationTextSize: .large
                    )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )

                // Device list card
                VStack(spacing: 0) {
                    HStack {
                        Text("Devices")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.bottom, 8)

                    List {
                        ForEach(buildingState.overviewData.devices.sorted(by: { $0.priority < $1.priority })) { device in
                            DevicePriorityRow(device: device)
                                .contentShape(Rectangle())
                        }
                        .onMove { indices, newOffset in
                            if let index = indices.first {
                                let device = buildingState.overviewData.devices[index]

                                Task {
                                    isLoading = true

                                    let newPriority =
                                        newOffset > index
                                        ? newOffset
                                        : newOffset + 1

                                    print("Old prio: \(device.priority), new prio: \(newPriority)")

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
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )

                Spacer()
            }
            .padding()

            if isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Devices")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.teal)
                }
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
