import SwiftUI

/// Watch setup sheet for the Battery → Car automation.
/// Watch-friendly Form: navigation-link Pickers for charging station,
/// charging mode, and phases; Stepper for the battery floor.
struct BatteryToCarSetupSheet: View {
    @Environment(AutomationWatchClient.self) private var client
    @Environment(\.dismiss) private var dismiss

    @State private var chargingDeviceId: String = ""
    @State private var minBatteryLevel: Int = 30
    @State private var fallbackChargingMode: ChargingMode = .withSolarPower
    @State private var phases: WallboxPhases = .three

    private var stations: [AutomationWatchSnapshot.WatchChargingStation] {
        client.snapshot?.chargingStations ?? []
    }

    private var canStart: Bool {
        !chargingDeviceId.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Station") {
                    Picker("Station", selection: $chargingDeviceId) {
                        Text("Choose…").tag("")
                        ForEach(stations) { s in
                            Text(s.name).tag(s.id)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Battery floor") {
                    Stepper(
                        value: $minBatteryLevel,
                        in: 5...90,
                        step: 5
                    ) {
                        Text("\(minBatteryLevel)%")
                            .monospacedDigit()
                    }
                }

                Section("After run, set wallbox to") {
                    Picker(
                        "Mode",
                        selection: $fallbackChargingMode
                    ) {
                        ForEach(
                            AutoResetChargingModeOptions.selectableModes
                        ) { mode in
                            Text(mode.localizedTitle).tag(mode)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Phases") {
                    Picker("Phases", selection: $phases) {
                        ForEach(WallboxPhases.allCases) { p in
                            Text(p.localizedTitle).tag(p)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section {
                    Button {
                        let params = AutomationParameters(
                            batteryToCar: .init(
                                chargingDeviceId: chargingDeviceId,
                                minBatteryLevel: minBatteryLevel,
                                fallbackChargingMode: fallbackChargingMode,
                                phases: phases
                            )
                        )
                        client.startAutomation(
                            .BatteryToCar,
                            parameters: params
                        )
                        dismiss()
                    } label: {
                        Label("Start", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canStart)
                }
            }
            .navigationTitle("Battery → Car")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if chargingDeviceId.isEmpty,
                   let first = stations.first
                {
                    chargingDeviceId = first.id
                }
            }
        }
    }
}
