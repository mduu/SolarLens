import SwiftUI

/// watchOS setup sheet for a single notification kind. Driven by a
/// numeric stepper sized for the small-screen UX (watch users can't
/// easily slide a precise slider).
struct WatchNotificationSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CurrentBuildingState.self) private var buildingState

    let kind: SolarLensNotification
    let existing: NotificationMonitor?

    @State private var comparison: NotificationComparison
    @State private var thresholdPercent: Int = 80
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
                initialValue: existing?.threshold ?? 80
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
                Section {
                    Picker("Condition", selection: $comparison) {
                        Text("≥ at-or-above")
                            .tag(NotificationComparison.equalOrAbove)
                        Text("≤ at-or-below")
                            .tag(NotificationComparison.equalOrBelow)
                    }
                }

                Section {
                    if kind.isPercent {
                        Stepper(
                            value: $thresholdPercent, in: 0...100, step: 1
                        ) {
                            HStack {
                                Text("Level")
                                Spacer()
                                Text("\(thresholdPercent)%")
                                    .monospacedDigit()
                            }
                        }
                    } else {
                        Stepper(
                            value: $thresholdKW, in: 0...kwUpperBound,
                            step: 0.1
                        ) {
                            HStack {
                                Text("Level")
                                Spacer()
                                Text(String(format: "%.1f kW", thresholdKW))
                                    .monospacedDigit()
                            }
                        }
                    }
                } header: {
                    Text("Threshold")
                }

                Section {
                    Picker("Repeat", selection: $repeatMode) {
                        Text("Notify once")
                            .tag(NotificationRepeatMode.once)
                        Text("Notify every time")
                            .tag(NotificationRepeatMode.everyReoccurrence)
                    }
                }

                Section {
                    Button(action: commit) {
                        Text(
                            existing == nil ? "Enable" : "Save changes"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
            .navigationTitle(String(localized: kind.localizedTitleKey))
        }
    }

    private var kwUpperBound: Double {
        switch kind {
        case .ChargingThroughput: return 22
        case .GridImport, .OverallConsumption: return 30
        default: return 20
        }
    }

    private func commit() {
        let thresholdInt: Int
        if kind.isPercent {
            thresholdInt = thresholdPercent
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
            AutomationWatchSession.shared.updateNotification(updated)
        } else {
            let monitor = NotificationMonitor(
                kind: kind,
                comparison: comparison,
                threshold: thresholdInt,
                repeatMode: repeatMode,
                enabledAt: Date()
            )
            AutomationWatchSession.shared.enableNotification(monitor)
        }
        dismiss()
    }
}
