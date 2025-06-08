//

import SwiftUI

struct BatteryModeOptionsSheet: View {
    var battery: Device
    var targetMode: BatteryMode

    var body: some View {
        ScrollView {
            
            VStack(alignment: .leading) {
                Button(action: {
                    // Action
                }) {
                    Spacer()

                    Text(
                        "Set '\(battery.name)' to '\(targetMode.GetBatteryModeName())'."
                    )
                    
                    Spacer()
                }
                .buttonBorderShape(.circle)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .background(Material.thick)
                .tint(.purple.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.bottom, 3)
                
                switch targetMode {
                case .Standard:
                    Text("To implement")
                    
                case .Eco:
                    ModeEcoOptions(battery: battery)
                    
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
            } // :VStack
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
            
        } // :ScrollView
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
