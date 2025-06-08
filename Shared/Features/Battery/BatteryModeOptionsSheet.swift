//

import SwiftUI

struct BatteryModeOptionsSheet: View {
    var battery: Device
    var targetMode: BatteryMode

    // Eco
    @State var ecoMin: Int = 0
    @State var ecoMorning: Int = 0
    @State var ecoMax: Int = 0

    var body: some View {
        ScrollView {

            VStack(alignment: .leading) {
                Button(action: {
                    Task {
                        await setTargetMode()
                    }
                }) {
                    Text(
                        "Set '\(battery.name)' to '\(targetMode.GetBatteryModeName())'."
                    )
                }
                .buttonBorderShape(.circle)
                .buttonStyle(.borderedProminent)
                .background(Material.thick)
                .tint(.purple.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.bottom, 3)

                switch targetMode {
                case .Standard:
                    Text("To implement")

                case .Eco:
                    ModeEcoOptions(
                        battery: battery,
                        minPercentage: $ecoMin,
                        morningPercentage: $ecoMorning,
                        maxPercentage: $ecoMax
                    )

                case .PeakShaving:
                    Text("To implement")

                case .TariffOptimized:
                    Text("To implement")

                case .Manual:
                    Text("To implement")

                case .StandardControlled:
                    Text("To implement")
                }

                Spacer()
            }  // :VStack
            .padding()
            .ignoresSafeArea(.all, edges: .bottom)
            .frame(maxWidth: .infinity)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Text("Battery options")
                            .foregroundColor(.purple)
                            .font(.headline)
                    }
                }  // :ToolbarItem
            }  // :.toolbar

        }  // :ScrollView
        .onAppear {
            if let batteryInfo = battery.batteryInfo {
                
                // Load existing Eco mode configuration
                ecoMin = batteryInfo.lowerSocLimit
                ecoMorning = batteryInfo.morningSocLimit
                ecoMax = batteryInfo.upperSocLimit
            }
        }
    }

    func setTargetMode() async {
        print("Setting battery mode to \(targetMode) ...")

        switch targetMode {
        case .Eco:
            print("Setting eco mode ...")
            

        default:
            print("Unsupported mode")
        }
    }
}

#Preview("Standard Controlled") {
    BatteryModeOptionsSheet(
        battery: Device.fakeBattery(),
        targetMode: .StandardControlled
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: .fake()
        )
    )
}

#Preview("Standard") {
    BatteryModeOptionsSheet(
        battery: Device.fakeBattery(),
        targetMode: .Standard
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: .fake()
        )
    )
}

#Preview("Eco") {
    BatteryModeOptionsSheet(
        battery: Device.fakeBattery(),
        targetMode: .Eco
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: .fake()
        )
    )
}

#Preview("Peak sh.") {
    BatteryModeOptionsSheet(
        battery: Device.fakeBattery(),
        targetMode: .PeakShaving
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: .fake()
        )
    )
}

#Preview("Manual") {
    BatteryModeOptionsSheet(
        battery: Device.fakeBattery(),
        targetMode: .Manual
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: .fake()
        )
    )
}

#Preview("Tariff") {
    BatteryModeOptionsSheet(
        battery: Device.fakeBattery(),
        targetMode: .TariffOptimized
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: .fake()
        )
    )
}
