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
                            // Battery status card
                            batteryStatusCard

                            // Forecast card
                            let forecast = model.overviewData.getBatteryForecast()
                            if forecast?.hasVisibleForecast == true {
                                forecastCard(forecast: forecast!)
                            }

                            // Device list card
                            let batteries = model.overviewData.devices.filter { $0.deviceType == .battery }
                            if !batteries.isEmpty {
                                batteryDevicesCard(batteries: batteries)
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

            if isLoading {
                ProgressView()
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
                        .foregroundColor(.green)
                }
            }
        }
    }

    // MARK: - Battery Status Card

    @ViewBuilder
    private var batteryStatusCard: some View {
        let level = model.overviewData.currentBatteryLevel ?? 0
        let charging = model.overviewData.currentBatteryChargeRate ?? 0
        let batteryColor = batteryAccentColor(level: level)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "battery.100percent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Battery")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(batteryColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: batteryIconName(level: level, charging: charging))
                        .font(.title3)
                        .foregroundStyle(batteryColor)
                        .symbolEffect(
                            .pulse.wholeSymbol,
                            options: .repeat(.continuous),
                            isActive: charging > 0
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(level)%")
                            .font(.headline)
                            .fontWeight(.bold)
                    }

                    if charging != 0 {
                        HStack(spacing: 4) {
                            Image(systemName: charging > 0 ? "arrow.up" : "arrow.down")
                                .font(.caption)
                                .foregroundStyle(charging > 0 ? .green : .orange)
                            Text(abs(charging).formatWattsAsWattsKiloWatts(widthUnit: true))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }

            BatteryIndicator(
                percentage: Double(level),
                showPercentage: false,
                height: 20
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Forecast Card

    @ViewBuilder
    private func forecastCard(forecast: BatteryForecast) -> some View {
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
                batteryForecast: forecast
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Battery Devices Card

    @ViewBuilder
    private func batteryDevicesCard(batteries: [Device]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
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

    // MARK: - Helpers

    private func batteryAccentColor(level: Int) -> Color {
        if level > 10 { return .green }
        if level > 6 { return .orange }
        return .red
    }

    private func batteryIconName(level: Int, charging: Int) -> String {
        if charging > 0 { return "battery.100percent.bolt" }
        if level >= 95 { return "battery.100percent" }
        if level >= 70 { return "battery.75percent" }
        if level >= 50 { return "battery.50percent" }
        if level >= 10 { return "battery.25percent" }
        return "battery.0percent"
    }
}

#Preview {
    NavigationView {
        BatterySheet()
            .environment(CurrentBuildingState.fake())
    }
}
