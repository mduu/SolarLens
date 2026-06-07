import SwiftUI

/// Setup sheet shared by every notification kind. Driven by the
/// `kind`'s canonical unit (percent for `BatteryLevel`, kW for the
/// others); the slider displays kW with one decimal and stores the
/// underlying watt value into the monitor.
///
/// If `existing` is non-nil, the sheet edits that monitor; otherwise it
/// creates a new one.
struct NotificationSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CurrentBuildingState.self) private var buildingState
    @State private var manager = NotificationManager.shared

    let kind: SolarLensNotification
    let existing: NotificationMonitor?

    @State private var comparison: NotificationComparison
    @State private var thresholdPercent: Double = 80
    @State private var thresholdKW: Double = 3.0
    @State private var repeatMode: NotificationRepeatMode

    init(
        kind: SolarLensNotification,
        existing: NotificationMonitor?
    ) {
        self.kind = kind
        self.existing = existing
        _comparison = State(
            initialValue: existing?.comparison ?? .equalOrAbove
        )
        _repeatMode = State(
            initialValue: existing?.repeatMode ?? .once
        )
        if kind.isPercent {
            _thresholdPercent = State(
                initialValue: Double(existing?.threshold ?? 80)
            )
        } else {
            _thresholdKW = State(
                initialValue: Double(existing?.threshold ?? 3000) / 1000.0
            )
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Condition") {
                    Picker("Notify when value is", selection: $comparison) {
                        Text("Equal or above")
                            .tag(NotificationComparison.equalOrAbove)
                        Text("Equal or below")
                            .tag(NotificationComparison.equalOrBelow)
                    }
                }

                Section {
                    if kind.isPercent {
                        percentSlider
                    } else {
                        kwSlider
                    }
                    if let now = currentValueDescription {
                        Label(now, systemImage: "gauge")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Threshold")
                } footer: {
                    Text(
                        "Solar Lens checks every few minutes. While Solar Lens is in the foreground the check is precise; in the background iOS decides when to wake the app."
                    )
                }

                Section {
                    Picker("Repeat", selection: $repeatMode) {
                        Text("Notify once")
                            .tag(NotificationRepeatMode.once)
                        Text("Notify on every re-occurrence")
                            .tag(NotificationRepeatMode.everyReoccurrence)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Repeat")
                } footer: {
                    Text(
                        repeatMode == .once
                            ? "Notifies once. After the notification fires, the monitor stops."
                            : "Notifies every time the condition is met. After firing, the monitor waits until the value clearly leaves the threshold before re-arming (no spam if the value flaps)."
                    )
                }
            }
            .navigationTitle(String(localized: kind.localizedTitleKey))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: commit) {
                    Label(
                        existing == nil
                            ? "Enable notification" : "Save changes",
                        systemImage: existing == nil
                            ? "bell.badge.fill" : "checkmark"
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
            }
        }
    }

    private var percentSlider: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Level")
                Spacer()
                Text("\(Int(thresholdPercent))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $thresholdPercent, in: 0...100, step: 1)
        }
    }

    private var kwSlider: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Level")
                Spacer()
                Text(String(format: "%.1f kW", thresholdKW))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $thresholdKW, in: 0...kwUpperBound, step: 0.1)
        }
    }

    /// Per-kind upper bound for the slider. Keeps the slider's resolution
    /// useful for typical values without artificially capping unusually
    /// large installations — overall consumption can be much higher than
    /// production in a moment.
    private var kwUpperBound: Double {
        switch kind {
        case .ChargingThroughput: return 22       // 3×32A @ 400V
        case .GridImport, .OverallConsumption: return 30
        default: return 20
        }
    }

    private var currentValueDescription: String? {
        let overview = buildingState.overviewData
        guard let value = NotificationManager.readValue(
            for: kind, from: overview
        ) else { return nil }
        if kind.isPercent {
            return String(format: String(localized: "Current: %d%%"), value)
        }
        return String(
            format: String(localized: "Current: %.1f kW"),
            Double(value) / 1000.0
        )
    }

    private func commit() {
        let thresholdInt: Int
        if kind.isPercent {
            thresholdInt = Int(thresholdPercent)
        } else {
            thresholdInt = Int((thresholdKW * 1000.0).rounded())
        }
        if let existing {
            let updated = NotificationMonitor(
                id: existing.id,
                kind: kind,
                comparison: comparison,
                threshold: thresholdInt,
                repeatMode: repeatMode,
                enabledAt: existing.enabledAt
            )
            manager.update(updated)
        } else {
            let monitor = NotificationMonitor(
                kind: kind,
                comparison: comparison,
                threshold: thresholdInt,
                repeatMode: repeatMode,
                enabledAt: Date()
            )
            manager.enable(monitor)
        }
        dismiss()
    }
}
