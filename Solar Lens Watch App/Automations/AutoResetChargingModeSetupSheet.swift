import SwiftUI

/// Watch setup sheet for the Auto-reset Charging Mode automation.
struct AutoResetChargingModeSetupSheet: View {
    @Environment(CurrentBuildingState.self) private var buildingState
    @Environment(\.dismiss) private var dismiss

    @State private var chargingDeviceId: String = ""
    @State private var activeChargingMode: ChargingMode = .alwaysCharge
    @State private var afterResetChargingMode: ChargingMode =
        .withSolarPower
    @State private var resetAt: Date = Date().addingTimeInterval(60 * 60)

    /// The picked moment without the seconds the DatePicker carries over from
    /// its initial value but never shows, so "14:30" means 14:30:00 — the same
    /// as on iPhone.
    private var startOfPickedMinute: Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute], from: resetAt
        )
        return calendar.date(from: comps) ?? resetAt
    }

    private var stations: [ChargingStation] {
        buildingState.overviewData.chargingStations
    }

    private var modesDifferent: Bool {
        activeChargingMode != afterResetChargingMode
    }

    private var canStart: Bool {
        !chargingDeviceId.isEmpty
            && modesDifferent
            && resetAt > Date().addingTimeInterval(60)
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

                Section("Active mode now") {
                    Picker(
                        "Active",
                        selection: $activeChargingMode
                    ) {
                        ForEach(
                            AutoResetChargingModeOptions.selectableModes
                        ) { mode in
                            Text(mode.localizedTitle).tag(mode)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("After reset, set to") {
                    Picker(
                        "After reset",
                        selection: $afterResetChargingMode
                    ) {
                        ForEach(
                            AutoResetChargingModeOptions.selectableModes
                        ) { mode in
                            Text(mode.localizedTitle).tag(mode)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Reset at") {
                    DatePicker(
                        "Reset at",
                        selection: $resetAt,
                        in: Date().addingTimeInterval(60)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                if !modesDifferent {
                    Section {
                        Label(
                            "Active and after-reset modes must be different.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    }
                }

                Section {
                    Button {
                        let params = AutomationParameters(
                            autoResetChargingMode: .init(
                                chargingDeviceId: chargingDeviceId,
                                activeChargingMode: activeChargingMode,
                                afterResetChargingMode:
                                    afterResetChargingMode,
                                resetAt: startOfPickedMinute
                            )
                        )
                        AutomationWatchSession.shared.startAutomation(
                            .AutoResetChargingMode,
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
            .navigationTitle("Auto-reset")
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
