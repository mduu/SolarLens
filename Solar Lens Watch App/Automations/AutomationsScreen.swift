import SwiftUI

/// Watch top-level Automations screen — mirrors the iOS
/// `AutomationScreen` structure: three slots, each rendered as either a
/// running card (when that automation is currently active) or an idle
/// card (which opens a setup sheet on tap).
struct AutomationsScreen: View {
    @Environment(AutomationWatchClient.self) private var client

    @State private var batteryToCarSetupPresented = false
    @State private var autoResetSetupPresented = false
    @State private var notifyBatteryLevelSetupPresented = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                batteryToCarSlot
                autoResetSlot
                notifyOnBatteryLevelSlot
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
        .sheet(isPresented: $batteryToCarSetupPresented) {
            BatteryToCarSetupSheet()
                .environment(client)
        }
        .sheet(isPresented: $autoResetSetupPresented) {
            AutoResetChargingModeSetupSheet()
                .environment(client)
        }
        .sheet(isPresented: $notifyBatteryLevelSetupPresented) {
            NotifyOnBatteryLevelSetupSheet()
                .environment(client)
        }
    }

    private var snapshot: AutomationWatchSnapshot? { client.snapshot }

    private var anotherIsActive: Bool {
        snapshot?.activeAutomation != nil
    }

    private var noBattery: Bool {
        !(snapshot?.prerequisites.hasAnyBattery ?? false)
    }

    private var noChargingStation: Bool {
        !(snapshot?.prerequisites.hasAnyCarChargingStation ?? false)
    }

    @ViewBuilder
    private var batteryToCarSlot: some View {
        if snapshot?.activeAutomation == .BatteryToCar,
           let runState = snapshot?.state?.batteryToCar,
           let runParams = snapshot?.parameters?.batteryToCar
        {
            BatteryToCarRunningCard(
                state: runState,
                params: runParams,
                onCancel: { client.cancelActiveAutomation() }
            )
        } else {
            BatteryToCarCard(
                isOtherActive: anotherIsActive,
                isHouseBatteryMissing: noBattery,
                onTap: { batteryToCarSetupPresented = true }
            )
        }
    }

    @ViewBuilder
    private var autoResetSlot: some View {
        if snapshot?.activeAutomation == .AutoResetChargingMode,
           let runState = snapshot?.state?.autoResetChargingMode,
           let runParams = snapshot?.parameters?.autoResetChargingMode
        {
            AutoResetChargingModeRunningCard(
                state: runState,
                params: runParams,
                onCancel: { client.cancelActiveAutomation() }
            )
        } else {
            AutoResetChargingModeCard(
                isOtherActive: anotherIsActive,
                isChargingStationMissing: noChargingStation,
                onTap: { autoResetSetupPresented = true }
            )
        }
    }

    @ViewBuilder
    private var notifyOnBatteryLevelSlot: some View {
        if snapshot?.activeAutomation == .NotifyOnBatteryLevel,
           let runState = snapshot?.state?.notifyOnBatteryLevel,
           let runParams = snapshot?.parameters?.notifyOnBatteryLevel
        {
            NotifyOnBatteryLevelRunningCard(
                state: runState,
                params: runParams,
                onCancel: { client.cancelActiveAutomation() }
            )
        } else {
            NotifyOnBatteryLevelCard(
                isOtherActive: anotherIsActive,
                isHouseBatteryMissing: noBattery,
                onTap: { notifyBatteryLevelSetupPresented = true }
            )
        }
    }
}
