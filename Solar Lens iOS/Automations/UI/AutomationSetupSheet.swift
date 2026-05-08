import SwiftUI

/// Setup sheet for the "Transfer from Battery to Car" automation.
struct AutomationSetupSheet: View {
    @Environment(CurrentBuildingState.self) var buildingState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStationId: String = ""
    @State private var minBatteryLevel: Double = 30
    @State private var fallbackMode: ChargingMode = .withSolarPower
    @State private var phases: WallboxPhases = .default

    private var stations: [ChargingStation] {
        buildingState.overviewData.chargingStations
    }
    private var selectedStation: ChargingStation? {
        stations.first { $0.id == selectedStationId } ?? stations.first
    }

    /// Hard floor for the slider.
    private let minFloorPct = 5

    /// Threshold below which the battery is too low to even start the
    /// automation. The slider needs at least one unit of range, so we
    /// require the SoC to be ≥ `minFloorPct + 2`.
    private var minSocToRun: Int { minFloorPct + 2 }

    /// The slider's upper bound is the current SoC minus 1 — picking a
    /// floor at or above the current battery level would mean the
    /// automation stops on the very first tick. Falls back to 90 % if
    /// the overview hasn't loaded yet. Always at least `minFloorPct +
    /// 1` so the SwiftUI Slider has a non-empty range (otherwise its
    /// `Normalizing` precondition crashes).
    private var maxFloorPct: Int {
        let current = buildingState.overviewData.currentBatteryLevel ?? 90
        return max(minFloorPct + 1, current - 1)
    }

    /// True when the battery is too low to run the automation usefully.
    /// In that state we hide the slider and the Start button.
    private var batteryTooLowToRun: Bool {
        guard let soc = buildingState.overviewData.currentBatteryLevel
        else { return false }
        return soc < minSocToRun
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
                } else if batteryTooLowToRun {
                    Section {
                        Label(
                            "Battery too low to run this automation",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.orange)
                    } footer: {
                        Text(
                            "Your house battery needs to be at least \(minSocToRun)% to run this automation."
                        )
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
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Don't go below (if possible)")
                                Spacer()
                                Text("\(Int(minBatteryLevel))%")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            Slider(
                                value: $minBatteryLevel,
                                in: Double(minFloorPct)...Double(maxFloorPct),
                                step: 1
                            )
                        }
                        .padding(.vertical, 4)
                    } footer: {
                        Text(
                            "We'll stop a few % earlier when iOS is throttling background updates so the battery stays above your floor when possible."
                        )
                    }

                    Section("After this automation") {
                        Picker("Switch wallbox to", selection: $fallbackMode) {
                            ForEach(
                                ChargingMode.allCases,
                                id: \.self
                            ) { mode in
                                Text(String(localized: mode.localizedTitle))
                                    .tag(mode)
                            }
                        }
                    }

                    Section {
                        Picker("Wallbox phases", selection: $phases) {
                            ForEach(WallboxPhases.allCases) { mode in
                                Text(String(localized: mode.localizedTitle))
                                    .tag(mode)
                            }
                        }
                    } footer: {
                        Text(
                            "Most domestic wallboxes in Switzerland, Germany, Austria and Denmark are 3-phase. Pick \"Auto\" if your wallbox switches between 1- and 3-phase based on load (e.g. go-eCharger, Easee)."
                        )
                    }
                }
            }
            .navigationTitle("Battery → Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !stations.isEmpty && !batteryTooLowToRun {
                    Button(action: startAutomation) {
                        Label("Start automation", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.orange)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .disabled(selectedStation == nil)
                }
            }
            .onAppear {
                if selectedStationId.isEmpty,
                   let first = stations.first {
                    selectedStationId = first.id
                }
                clampFloorToCurrentSoc()
                phases = WallboxPhasesStore.phases(for: selectedStationId)
            }
            .onChange(of: maxFloorPct) { _, _ in
                clampFloorToCurrentSoc()
            }
            .onChange(of: selectedStationId) { _, newId in
                phases = WallboxPhasesStore.phases(for: newId)
            }
            .onChange(of: phases) { _, newPhases in
                WallboxPhasesStore.save(
                    newPhases, for: selectedStationId
                )
            }
        }
    }

    private func clampFloorToCurrentSoc() {
        let lo = Double(minFloorPct)
        let hi = Double(maxFloorPct)
        if minBatteryLevel < lo { minBatteryLevel = lo }
        if minBatteryLevel > hi { minBatteryLevel = hi }
    }

    private func startAutomation() {
        guard let station = selectedStation else { return }
        let params = AutomationParameters(
            batteryToCar: AutomationBatteryToCarParameters(
                chargingDeviceId: station.id,
                minBatteryLevel: Int(minBatteryLevel),
                fallbackChargingMode: fallbackMode,
                phases: phases
            )
        )
        AutomationManager.shared.startAutomation(
            automation: .BatteryToCar,
            parameters: params
        )
        dismiss()
    }
}

extension AutomationParameters {
    init(batteryToCar: AutomationBatteryToCarParameters) {
        self.batteryToCar = batteryToCar
    }
}

#Preview {
    AutomationSetupSheet()
        .environment(CurrentBuildingState(
            energyManagerClient: FakeEnergyManager()
        ))
}
