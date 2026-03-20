import SwiftUI

struct DevicePrioritySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState

    @ObservedObject var pinnedConfig: PinnedDevicesConfiguration
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

            ScrollView {
                VStack(spacing: 16) {
                    // Consumption chart card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.pie")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Consumption")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ConsumptionPieChart(
                            totalCurrentConsumptionInWatt: buildingState.overviewData
                                .currentOverallConsumption,
                            deviceConsumptions: getDeviceConsumptions(),
                            legendPosition: .right,
                            annotationTextSize: .large
                        )
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )

                    // Device list card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Devices")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Image(systemName: "arrow.up.arrow.down")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        List {
                            ForEach(buildingState.overviewData.devices.sorted(by: { $0.priority < $1.priority })) { device in
                                DevicePriorityRow(device: device, pinnedConfig: pinnedConfig)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.visible)
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

                                        await buildingState.setSensorPriority(
                                            sensorId: device.id,
                                            newPriority: newPriority
                                        )

                                        isLoading = false
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollDisabled(true)
                        .frame(minHeight: CGFloat(buildingState.overviewData.devices.count) * 56)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                }
                .padding()
            }

            if isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Consumption")
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
        DevicePrioritySheet(pinnedConfig: PinnedDevicesConfiguration())
            .environment(CurrentBuildingState.fake())
    }
}
