import SwiftUI

struct BatterySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @State var isLoading: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.06, green: 0.08, blue: 0.06), Color(red: 0.05, green: 0.05, blue: 0.05)]
                    : [Color(red: 0.94, green: 0.98, blue: 0.94), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if model.overviewData.currentBatteryLevel != nil
                        || model.overviewData.currentBatteryChargeRate != nil
                    {
                        if !model.overviewData.isStaleData {
                            // Battery gauge card
                            VStack(spacing: 12) {
                                BatteryIndicator(
                                    percentage: Double(model.overviewData.currentBatteryLevel ?? 0),
                                    showPercentage: true,
                                    height: 30
                                )

                                let charging = model.overviewData.currentBatteryChargeRate ?? 0
                                if charging != 0 {
                                    HStack(spacing: 8) {
                                        Image(systemName: charging >= 0 ? "arrow.right.circle.fill" : "arrow.left.circle.fill")
                                            .foregroundColor(charging >= 0 ? .green : .orange)

                                        Text(charging >= 0 ? "In:" : "Out:")
                                            .foregroundColor(charging >= 0 ? .green : .orange)

                                        Text("\(abs(charging)) W")
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )

                            // Forecast card
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("Forecast")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                BatteryForecastView(
                                    batteryForecast: model.overviewData.getBatteryForecast()
                                )
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )

                            // Device list card
                            let batteries = model.overviewData.devices.filter { $0.deviceType == .battery }
                            if !batteries.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "battery.100percent")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("Devices")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    ForEach(batteries) { battery in
                                        BatteryView(battery: battery)
                                        if battery.id != batteries.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                )
                            }

                        } else {
                            Text("Stale data!")
                                .foregroundColor(.red)
                        }
                    } else {
                        Text("No battery data present!")
                            .font(.footnote)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Battery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.purple)
                }
            }
        }

        if isLoading {
            ProgressView()
        }
    }
}

#Preview {
    NavigationView {
        BatterySheet()
            .environment(CurrentBuildingState.fake())
    }
}
