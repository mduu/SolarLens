//

import SwiftUI

struct BatteryView: View {
    let battery: Device

    @State var showModeSheet: Bool = false

    var body: some View {
        Button(action: {
            showModeSheet = true
        }) {
            HStack {
                Image(systemName: "battery.100percent.circle")
                    .font(.title2)
                    .fontWeight(.thin)
                    .foregroundColor(.white.opacity(0.8))

                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {

                        Text(battery.name)
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        if battery.currentPowerInWatts != 0 {
                            Text(
                                battery.currentPowerInWatts
                                    .formatWattsAsWattsKiloWatts(
                                        widthUnit: true
                                    )
                            )
                            .font(.footnote)
                            .foregroundColor(
                                battery.currentPowerInWatts < 0
                                    ? .orange
                                    : battery.currentPowerInWatts > 0
                                        ? .green
                                        : .white
                            )
                            .padding(.trailing, 2)
                        }
                    }

                    HStack {
                        Text(getBatteryModeText())
                    }
                }

                Spacer()
            }
        }
        .tint(.purple)
        .sheet(isPresented: $showModeSheet) {
            BatteryModeSheet(battery: battery)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("Battery mode")
                            .foregroundColor(.purple)
                            .font(.headline)
                    }  // :ToolbarItem
                }  // :.toolbar
        }
    }

    func getBatteryModeText() -> LocalizedStringResource {
        switch battery.batteryInfo?.modeInfo.batteryMode {
        case .Standard:
            "Standard"
        case .Eco:
            "Eco"
        case .PeakShaving:
            "Peak shaving"
        case .Manual:
            "Manual"
        case .TariffOptimized:
            "Tariff optimized"
        case .StandardControlled:
            battery.batteryInfo?.modeInfo.standardStandaloneAllowed ?? false
                ? "Standalone"
                : "Standard"
        case nil:
            ""
        }
    }
}

#Preview {
    ZStack {

        LinearGradient(
            gradient: Gradient(colors: [
                .purple.opacity(0.4), .purple.opacity(0.1),
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        BatteryView(
            battery: Device(
                id: "1234",
                deviceType: .battery,
                name: "Test 1",
                priority: 1,
                currentPowerInWatts: 3250,
                batteryInfo: BatteryInfo.fake()
            )
        )
    }
}
