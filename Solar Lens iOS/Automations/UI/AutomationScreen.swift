import SwiftUI

struct AutomationScreen: View {
    @Environment(CurrentBuildingState.self) var buildingState
    @State private var manager = AutomationManager.shared
    @State private var setupSheetPresented = false
    @State private var logSheetPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerCard

                    if manager.activeAutomation == .BatteryToCar,
                       let runState = manager.activeStateSnapshot?
                        .batteryToCar,
                       let runParams = manager.activeParametersSnapshot?
                        .batteryToCar {
                        BatteryToCarRunningCard(
                            state: runState,
                            params: runParams,
                            onCancel: {
                                manager.cancelActiveAutomation()
                            }
                        )
                        .padding(.horizontal, 4)
                    } else {
                        BatteryToCarCard(
                            isOtherActive: manager.activeAutomation != nil,
                            isHouseBatteryMissing:
                                !buildingState.overviewData.hasAnyBattery,
                            onTap: {
                                if manager.activeAutomation == nil
                                    && buildingState.overviewData
                                        .hasAnyBattery {
                                    setupSheetPresented = true
                                }
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Automation")
            .toolbar {
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
            .sheet(isPresented: $setupSheetPresented) {
                AutomationSetupSheet()
            }
            .sheet(isPresented: $logSheetPresented) {
                AutomationLogView()
            }
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
                "Run advanced workflows with your solar setup. iOS will keep them running in the background as best it can — keep Solar Lens open for the most precise control."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
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
