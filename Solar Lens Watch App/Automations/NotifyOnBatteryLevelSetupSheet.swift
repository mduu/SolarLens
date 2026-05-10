import SwiftUI

/// Watch setup sheet for the Notify on Battery Level automation.
struct NotifyOnBatteryLevelSetupSheet: View {
    @Environment(AutomationWatchClient.self) private var client
    @Environment(\.dismiss) private var dismiss

    @State private var targetBatteryLevel: Int = 80
    @State private var comparison: NotifyOnBatteryLevelPayload.Comparison =
        .equalOrAbove

    var body: some View {
        NavigationStack {
            Form {
                Section("Notify when battery is") {
                    Picker("Comparison", selection: $comparison) {
                        Text("≥ at or above").tag(
                            NotifyOnBatteryLevelPayload.Comparison
                                .equalOrAbove
                        )
                        Text("≤ at or below").tag(
                            NotifyOnBatteryLevelPayload.Comparison
                                .equalOrBelow
                        )
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Target level") {
                    Stepper(
                        value: $targetBatteryLevel,
                        in: 0...100,
                        step: 2
                    ) {
                        Text("\(targetBatteryLevel)%")
                            .font(.caption)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    if let now = client.snapshot?.currentBatteryLevel {
                        Text("Now: \(now)%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        let params = AutomationParameters(
                            notifyOnBatteryLevel: .init(
                                targetBatteryLevel: targetBatteryLevel,
                                comparison: comparison
                            )
                        )
                        client.startAutomation(
                            .NotifyOnBatteryLevel,
                            parameters: params
                        )
                        dismiss()
                    } label: {
                        Label("Start", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Battery Alert")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
