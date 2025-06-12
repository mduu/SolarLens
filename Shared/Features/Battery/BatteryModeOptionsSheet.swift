//

import SwiftUI

struct BatteryModeOptionsSheet: View {
    var battery: Device
    var targetMode: BatteryMode

    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState
    @Environment(\.dismiss) var dismiss

    @State var hasError: Bool = false

    // Standard Controlled
    @State var stdCtrlAllowStandalone: Bool = false
    @State var stdCtrlMin: Int = 0
    @State var stdCtrlMax: Int = 0

    // Eco
    @State var ecoMin: Int = 0
    @State var ecoMorning: Int = 0
    @State var ecoMax: Int = 0
    
    // Peak shaving
    @State var psSocDischargeLimit: Int = 0
    @State var psSocMaxLimit: Int = 0
    @State var psMaxGridPower: Int = 0
    @State var psRechargePower: Int = 0


    var body: some View {
        ZStack {
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
                        Text("Not supported!")

                    case .Eco:
                        EcoOptionsView(
                            battery: battery,
                            minPercentage: $ecoMin,
                            morningPercentage: $ecoMorning,
                            maxPercentage: $ecoMax
                        )

                    case .PeakShaving:
                        PeakShavingOptionsView(
                            battery: battery,
                            socDischargeLimit: $psSocDischargeLimit,
                            socMaxLimit: $psSocMaxLimit,
                            maxGridPower: $psMaxGridPower,
                            rechargePower: $psRechargePower
                        )

                    case .TariffOptimized:
                        Text("To implement")

                    case .Manual:
                        Text("To implement")

                    case .StandardControlled:
                        StandardControlledOptionsView(
                            battery: battery,
                            allowStandalone: $stdCtrlAllowStandalone,
                            minPercentage: $stdCtrlMin,
                            maxPercentage: $stdCtrlMax
                        )
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
                    ecoMin = batteryInfo.modeInfo.dischargeSocLimit
                    ecoMorning = batteryInfo.modeInfo.morningSocLimit
                    ecoMax = batteryInfo.modeInfo.chargingSocLimit
                    
                    // Load existing Standard Controlled mode configuration
                    stdCtrlAllowStandalone = batteryInfo.modeInfo.standardStandaloneAllowed
                    stdCtrlMin = batteryInfo.modeInfo.standardLowerSocLimit
                    stdCtrlMax = batteryInfo.modeInfo.standardUpperSocLimit
                    
                    // Load existing Peak Shaving mode configuration
                    psSocDischargeLimit = batteryInfo.modeInfo.peakShavingSocDischargeLimit
                    psSocMaxLimit = batteryInfo.modeInfo.peakShavingSocMaxLimit
                    psMaxGridPower = batteryInfo.modeInfo.peakShavingMaxGridPower
                    psRechargePower = batteryInfo.modeInfo.peakShavingRechargePower

                }
            }
        }

        if model.isChangingBatteryMode {
            ProgressView()
        }
    }

    func setTargetMode() async {
        print("Setting battery mode to \(targetMode) ...")

        guard
            let existingModeInfo: BatteryModeInfo = battery.batteryInfo?
                .modeInfo
        else {
            hasError = true
            return
        }

        print("Setting battery mode to \(targetMode) ...")

        let batteryInfo: BatteryModeInfo =
            switch targetMode {
            case .Eco:
                existingModeInfo.createClone(
                    batteryMode: .Eco,
                    dischargeSocLimit: ecoMin,
                    chargingSocLimit: ecoMax,
                    morningSocLimit: ecoMorning
                )

            case .Standard:
                existingModeInfo.createClone(
                    batteryMode: .Standard,
                )
            case .PeakShaving:
                existingModeInfo.createClone(
                    batteryMode: .PeakShaving,
                    peakShavingSocDischargeLimit: psSocDischargeLimit,
                    peakShavingSocMaxLimit: psSocMaxLimit,
                    peakShavingMaxGridPower: psMaxGridPower,
                    peakShavingRechargePower: psRechargePower
                )
            case .Manual:
                existingModeInfo.createClone(
                    batteryMode: .Manual,
                )
            case .TariffOptimized:
                existingModeInfo.createClone(
                    batteryMode: .TariffOptimized
                )
            case .StandardControlled:
                existingModeInfo.createClone(
                    batteryMode: .StandardControlled,
                    standardStandaloneAllowed: stdCtrlAllowStandalone,
                    standardLowerSocLimit: stdCtrlMin,
                    standardUpperSocLimit: stdCtrlMax
                )
            }

        await model.setBatteryMode(
            sensorId: battery.id,
            batteryModeInfo: batteryInfo
        )

        if model.batteryModeSetSuccessfully == true {
            dismiss()
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
