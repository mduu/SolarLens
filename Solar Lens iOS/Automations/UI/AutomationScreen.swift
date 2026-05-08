import SwiftUI

struct AutomationScreen: View {
    @Environment(CurrentBuildingState.self) var buildingState
    @State private var manager = AutomationManager.shared
    @State private var batteryToCarSetupPresented = false
    @State private var autoResetSetupPresented = false
    @State private var notifyBatteryLevelSetupPresented = false
    @State private var logSheetPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerCard
                    mainContent
                }
                .padding()
            }
            .navigationTitle("Automation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Larger title rendered via the principal slot. We keep
                // `navigationTitle("Automation")` for accessibility, system
                // back-button label etc., but the principal item overrides
                // the rendered inline title with a bigger font — without
                // dropping back to `.large` mode and its top whitespace.
                ToolbarItem(placement: .principal) {
                    Text("Automation")
                        .font(.title2.weight(.bold))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        logSheetPresented = true
                    } label: {
                        Image(systemName: "doc.text.magnifyingglass")
                    }
                    .accessibilityLabel("Show automation log")
                    .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $batteryToCarSetupPresented) {
                AutomationSetupSheet()
            }
            .sheet(isPresented: $autoResetSetupPresented) {
                AutoResetChargingModeSetupSheet()
            }
            .sheet(isPresented: $notifyBatteryLevelSetupPresented) {
                NotifyOnBatteryLevelSetupSheet()
            }
            .sheet(isPresented: $logSheetPresented) {
                AutomationLogView()
            }
        }
    }

    /// Either the running card for the currently-active automation, or
    /// the list of idle cards when nothing is running.
    @ViewBuilder
    private var mainContent: some View {
        switch manager.activeAutomation {
        case .BatteryToCar:
            if let runState = manager.activeStateSnapshot?.batteryToCar,
               let runParams = manager.activeParametersSnapshot?
                .batteryToCar {
                BatteryToCarRunningCard(
                    state: runState,
                    params: runParams,
                    onCancel: { manager.cancelActiveAutomation() }
                )
                .padding(.horizontal, 4)
            } else {
                idleCards
            }
        case .AutoResetChargingMode:
            if let runState = manager.activeStateSnapshot?
                .autoResetChargingMode,
               let runParams = manager.activeParametersSnapshot?
                .autoResetChargingMode {
                AutoResetChargingModeRunningCard(
                    state: runState,
                    params: runParams,
                    onCancel: { manager.cancelActiveAutomation() }
                )
                .padding(.horizontal, 4)
            } else {
                idleCards
            }
        case .NotifyOnBatteryLevel:
            if let runState = manager.activeStateSnapshot?
                .notifyOnBatteryLevel,
               let runParams = manager.activeParametersSnapshot?
                .notifyOnBatteryLevel {
                NotifyOnBatteryLevelRunningCard(
                    state: runState,
                    params: runParams,
                    onCancel: { manager.cancelActiveAutomation() }
                )
                .padding(.horizontal, 4)
            } else {
                idleCards
            }
        case .none:
            idleCards
        }
    }

    private var idleCards: some View {
        VStack(spacing: 12) {
            BatteryToCarCard(
                isOtherActive: manager.activeAutomation != nil,
                isHouseBatteryMissing:
                    !buildingState.overviewData.hasAnyBattery,
                onTap: {
                    if manager.activeAutomation == nil
                        && buildingState.overviewData.hasAnyBattery {
                        batteryToCarSetupPresented = true
                    }
                }
            )

            AutoResetChargingModeCard(
                isOtherActive: manager.activeAutomation != nil,
                onTap: {
                    if manager.activeAutomation == nil {
                        autoResetSetupPresented = true
                    }
                }
            )

            NotifyOnBatteryLevelCard(
                isOtherActive: manager.activeAutomation != nil,
                isHouseBatteryMissing:
                    !buildingState.overviewData.hasAnyBattery,
                onTap: {
                    if manager.activeAutomation == nil
                        && buildingState.overviewData.hasAnyBattery {
                        notifyBatteryLevelSetupPresented = true
                    }
                }
            )
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Smart automations")
                    .font(.headline)
            }
            Text(
                "Let Solar Lens handle smart routines for you — charging, schedules and battery alerts."
            )
            .font(.callout)
            .foregroundStyle(.secondary)

            Label(
                "Keep Solar Lens open for the most precise timing.",
                systemImage: "info.circle"
            )
            .font(.caption)
            .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

#Preview {
    AutomationScreen()
        .environment(CurrentBuildingState(
            energyManagerClient: FakeEnergyManager()
        ))
}
