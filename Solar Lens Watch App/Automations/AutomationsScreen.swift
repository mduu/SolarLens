import SwiftUI

/// Watch top-level Automations screen — mirrors the iOS
/// `AutomationScreen` structure: three slots, each rendered as either a
/// running card (when that automation is currently active) or an idle
/// card (which opens a setup sheet on tap).
///
/// Watch-specific UX deviation from iOS: when an automation is active,
/// its running card is hoisted to the top of the scroll view so the
/// user lands on the most relevant info first instead of having to
/// scroll past disabled idle cards. iOS keeps a fixed slot order; the
/// watch screen is too small for that.
struct AutomationsScreen: View {
    @Environment(AutomationWatchClient.self) private var client

    @State private var batteryToCarSetupPresented = false
    @State private var autoResetSetupPresented = false
    @State private var notifyBatteryLevelSetupPresented = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    .orange.opacity(0.5), .orange.opacity(0.2),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 8) {
                    if snapshot == nil {
                        waitingForIPhoneHint
                    }
                    ForEach(orderedSlots, id: \.self) { slot in
                        view(for: slot)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
            }
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

    /// Compact placeholder shown until the iPhone has delivered the
    /// first snapshot. Without it, the idle cards would render
    /// disabled with a misleading "Requires a house battery" message
    /// — the prerequisites are unknown at this point, not absent.
    private var waitingForIPhoneHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "iphone.gen3")
                .foregroundStyle(.secondary)
            Text("Waiting for iPhone…")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var anotherIsActive: Bool {
        snapshot?.activeAutomation != nil
    }

    /// True only when we **know** the system has no house battery. With
    /// no snapshot yet we treat the answer as unknown (false) so we
    /// don't lie about "requires a house battery" before the first
    /// state push from the iPhone has landed.
    private var noBattery: Bool {
        guard let snap = snapshot else { return false }
        return !snap.prerequisites.hasAnyBattery
    }

    private var noChargingStation: Bool {
        guard let snap = snapshot else { return false }
        return !snap.prerequisites.hasAnyCarChargingStation
    }

    /// Stable canonical order — matches the iOS screen. Reordered at
    /// render time so the running automation lands first.
    private let canonicalOrder: [Automation] = [
        .BatteryToCar, .AutoResetChargingMode, .NotifyOnBatteryLevel,
    ]

    private var orderedSlots: [Automation] {
        guard let active = snapshot?.activeAutomation else {
            return canonicalOrder
        }
        return [active] + canonicalOrder.filter { $0 != active }
    }

    @ViewBuilder
    private func view(for slot: Automation) -> some View {
        switch slot {
        case .BatteryToCar: batteryToCarSlot
        case .AutoResetChargingMode: autoResetSlot
        case .NotifyOnBatteryLevel: notifyOnBatteryLevelSlot
        }
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
