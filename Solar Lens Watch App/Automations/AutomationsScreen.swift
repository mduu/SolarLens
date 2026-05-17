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
///
/// Data sources, by design:
/// - **Automation state** (active / state / parameters) comes from the
///   iPhone via `AutomationStateStore.snapshot` — only the iPhone
///   runner knows it. The WCSession plumbing lives in
///   `AutomationWatchSession` and is intentionally invisible to this
///   view.
/// - **Solar Manager telemetry** (prerequisites flags, charging
///   stations) is loaded by the watch itself via `CurrentBuildingState`
///   over REST, identical to the iOS app. We intentionally do NOT pipe
///   it through WCSession to avoid a periodic push every 15 s.
struct AutomationsScreen: View {
    @Environment(AutomationStateStore.self) private var store
    @Environment(CurrentBuildingState.self) private var buildingState

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
                .environment(buildingState)
        }
        .sheet(isPresented: $autoResetSetupPresented) {
            AutoResetChargingModeSetupSheet()
                .environment(buildingState)
        }
        .sheet(isPresented: $notifyBatteryLevelSetupPresented) {
            NotifyOnBatteryLevelSetupSheet()
                .environment(buildingState)
        }
    }

    private var snapshot: AutomationWatchSnapshot? { store.snapshot }

    private var anotherIsActive: Bool {
        snapshot?.activeAutomation != nil
    }

    private var noBattery: Bool {
        !buildingState.overviewData.hasAnyBattery
    }

    private var noChargingStation: Bool {
        !buildingState.overviewData.hasAnyCarChargingStation
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
                onCancel: {
                    AutomationWatchSession.shared.cancelActiveAutomation()
                }
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
                onCancel: {
                    AutomationWatchSession.shared.cancelActiveAutomation()
                }
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
                onCancel: {
                    AutomationWatchSession.shared.cancelActiveAutomation()
                }
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
