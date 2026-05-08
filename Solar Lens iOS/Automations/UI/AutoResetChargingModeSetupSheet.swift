import SwiftUI

/// Setup sheet for the "Auto-reset Charging Mode" automation.
struct AutoResetChargingModeSetupSheet: View {
    @Environment(CurrentBuildingState.self) var buildingState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStationId: String = ""
    @State private var activeMode: ChargingMode = .alwaysCharge
    @State private var afterResetMode: ChargingMode = .withSolarPower
    @State private var resetAt: Date = AutoResetChargingModeSetupSheet
        .defaultResetDate()

    private var stations: [ChargingStation] {
        buildingState.overviewData.chargingStations
    }

    private var selectedStation: ChargingStation? {
        stations.first { $0.id == selectedStationId } ?? stations.first
    }

    /// Earliest reset date the user can pick. We require at least 60 s in
    /// the future so an immediately-overdue reset doesn't fire on the
    /// very first tick (which would be confusing — the user thinks they
    /// just started a multi-hour run).
    private var minResetDate: Date {
        Date().addingTimeInterval(60)
    }

    private var canStart: Bool {
        selectedStation != nil
            && activeMode != afterResetMode
            && resetAt > minResetDate
    }

    private var modes: [ChargingMode] {
        AutomationAutoResetChargingMode.selectableModes
    }

    var body: some View {
        NavigationStack {
            Form {
                if stations.isEmpty {
                    Section {
                        Text(
                            "No charging stations found. Add one in Solar Manager first."
                        )
                        .foregroundStyle(.secondary)
                    }
                } else {
                    if stations.count > 1 {
                        Section("Charging station") {
                            Picker(
                                "Charging station",
                                selection: $selectedStationId
                            ) {
                                ForEach(stations) { station in
                                    Text(station.name).tag(station.id)
                                }
                            }
                        }
                    }

                    Section {
                        Picker(
                            "Active mode",
                            selection: $activeMode
                        ) {
                            ForEach(modes) { mode in
                                Text(mode.localizedTitle).tag(mode)
                            }
                        }
                    } header: {
                        Text("Active charging mode")
                    } footer: {
                        Text(
                            "The mode the wallbox is set to immediately when this automation starts."
                        )
                    }

                    Section {
                        DatePicker(
                            "Reset date and time",
                            selection: $resetAt,
                            in: minResetDate...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    } header: {
                        Text("Reset at")
                    } footer: {
                        Text(
                            "iOS may delay the reset by a few minutes if the device is asleep at that time. Keep Solar Lens running for the most precise reset."
                        )
                    }

                    Section {
                        Picker(
                            "After-reset mode",
                            selection: $afterResetMode
                        ) {
                            ForEach(modes) { mode in
                                Text(mode.localizedTitle).tag(mode)
                            }
                        }
                    } header: {
                        Text("After reset")
                    } footer: {
                        Text(
                            "The mode the wallbox is reset to once the date and time is reached, or when you cancel the automation."
                        )
                    }

                    if activeMode == afterResetMode {
                        Section {
                            Label(
                                "Active and after-reset modes must be different",
                                systemImage: "info.circle"
                            )
                            .foregroundStyle(.orange)
                            .font(.footnote)
                        }
                    }
                }
            }
            .navigationTitle("Auto-reset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !stations.isEmpty {
                    Button(action: startAutomation) {
                        Label(
                            "Start automation", systemImage: "play.fill"
                        )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.orange)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .disabled(!canStart)
                }
            }
            .onAppear {
                if selectedStationId.isEmpty,
                   let first = stations.first {
                    selectedStationId = first.id
                }
                if resetAt < minResetDate {
                    resetAt = Self.defaultResetDate()
                }
            }
        }
    }

    private func startAutomation() {
        guard let station = selectedStation else { return }

        // The DatePicker hides seconds (`displayedComponents:
        // [.date, .hourAndMinute]`), so the user-picked value lands on
        // the *start* of their chosen minute. The user expects "14:30"
        // to mean the 14:30 minute as a whole — i.e. the reset should
        // fire after that minute completes (14:31:00) rather than at
        // its very start. We snap to the start of the chosen minute and
        // add 60 s so the wallbox is guaranteed to stay on the active
        // mode for the full picked minute and never switch even a
        // fraction of a second early.
        let calendar = Calendar.current
        let comps = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute], from: resetAt
        )
        let startOfMinute = calendar.date(from: comps) ?? resetAt
        let effectiveResetAt = startOfMinute.addingTimeInterval(60)

        let params = AutomationAutoResetChargingModeParameters(
            chargingDeviceId: station.id,
            activeChargingMode: activeMode,
            afterResetChargingMode: afterResetMode,
            resetAt: effectiveResetAt
        )

        AutomationManager.shared.startAutomation(
            automation: .AutoResetChargingMode,
            parameters: AutomationParameters(
                batteryToCar: nil,
                autoResetChargingMode: params
            )
        )

        dismiss()
    }

    /// Default reset date: in 1 hour, rounded to the next 5-minute mark
    /// so the picker opens on a tidy value.
    private static func defaultResetDate() -> Date {
        let now = Date()
        let target = now.addingTimeInterval(60 * 60)
        let calendar = Calendar.current
        var comps = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute], from: target
        )
        let minute = comps.minute ?? 0
        let rounded = ((minute + 4) / 5) * 5
        comps.minute = rounded
        return calendar.date(from: comps) ?? target
    }
}
