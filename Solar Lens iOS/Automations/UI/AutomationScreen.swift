import SwiftUI

struct AutomationScreen: View {
    @Environment(CurrentBuildingState.self) var buildingState
    @State private var manager = AutomationManager.shared
    @State private var batteryToCarSetupPresented = false
    @State private var autoResetSetupPresented = false
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
            .sheet(isPresented: $logSheetPresented) {
                AutomationLogView()
            }
        }
    }

    /// Always shows every automation. Whichever one is currently
    /// running renders as a *running* card; the others render as
    /// *disabled* idle cards so the user can still see them but has to
    /// cancel the active automation first to start a different one.
    /// Idle cards also disable themselves on missing prerequisites
    /// (battery present for the battery automations, charging station
    /// present for the charging-mode automation).
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 12) {
            batteryToCarSlot
            autoResetSlot
        }
    }

    private var anotherIsActive: Bool {
        manager.activeAutomation != nil
    }
    private var noBattery: Bool {
        !buildingState.overviewData.hasAnyBattery
    }
    private var noChargingStation: Bool {
        !buildingState.overviewData.hasAnyCarChargingStation
    }

    @ViewBuilder
    private var batteryToCarSlot: some View {
        if manager.activeAutomation == .BatteryToCar,
           let runState = manager.activeStateSnapshot?.batteryToCar,
           let runParams = manager.activeParametersSnapshot?.batteryToCar
        {
            BatteryToCarRunningCard(
                state: runState,
                params: runParams,
                onCancel: { manager.cancelActiveAutomation() }
            )
            .padding(.horizontal, 4)
        } else {
            BatteryToCarCard(
                isOtherActive: anotherIsActive,
                isHouseBatteryMissing: noBattery,
                onTap: {
                    if !anotherIsActive && !noBattery {
                        batteryToCarSetupPresented = true
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var autoResetSlot: some View {
        if manager.activeAutomation == .AutoResetChargingMode,
           let runState = manager.activeStateSnapshot?.autoResetChargingMode,
           let runParams = manager.activeParametersSnapshot?
            .autoResetChargingMode
        {
            AutoResetChargingModeRunningCard(
                state: runState,
                params: runParams,
                onCancel: { manager.cancelActiveAutomation() }
            )
            .padding(.horizontal, 4)
        } else {
            AutoResetChargingModeCard(
                isOtherActive: anotherIsActive,
                isChargingStationMissing: noChargingStation,
                onTap: {
                    if !anotherIsActive && !noChargingStation {
                        autoResetSetupPresented = true
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
