import SwiftUI

/// Setup sheet for the "Notify on battery level" automation.
struct NotifyOnBatteryLevelSetupSheet: View {
    @Environment(CurrentBuildingState.self) var buildingState
    @Environment(\.dismiss) private var dismiss

    @State private var targetLevel: Double = 80
    @State private var comparison:
        NotifyOnBatteryLevelPayload.Comparison = .equalOrAbove

    private var currentLevel: Int? {
        buildingState.overviewData.currentBatteryLevel
    }

    private var canStart: Bool {
        // Always allow — even if the condition is already met at start
        // time, the automation finishes immediately and the user gets
        // their notification right away. That's intentional.
        true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Notify when battery is", selection: $comparison) {
                        Text("Equal or above")
                            .tag(NotifyOnBatteryLevelPayload.Comparison.equalOrAbove)
                        Text("Equal or below")
                            .tag(NotifyOnBatteryLevelPayload.Comparison.equalOrBelow)
                    }
                } header: {
                    Text("Condition")
                }

                Section {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Battery level")
                            Spacer()
                            Text("\(Int(targetLevel))%")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: $targetLevel,
                            in: 0...100,
                            step: 1
                        )
                    }
                    if let current = currentLevel {
                        Label(
                            "Current battery: \(current)%",
                            systemImage: "battery.50"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Target")
                } footer: {
                    Text(
                        "Solar Lens checks the battery every few minutes and notifies you when the condition is met. The automation auto-cancels after 24 hours if the level isn't reached."
                    )
                }
            }
            .navigationTitle("Notify on battery level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
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
                .disabled(!canStart)
            }
        }
    }

    private func startAutomation() {
        let params = AutomationNotifyOnBatteryLevelParameters(
            targetBatteryLevel: Int(targetLevel),
            comparison: comparison
        )
        AutomationManager.shared.startAutomation(
            automation: .NotifyOnBatteryLevel,
            parameters: AutomationParameters(
                batteryToCar: nil,
                autoResetChargingMode: nil,
                notifyOnBatteryLevel: params
            )
        )
        dismiss()
    }
}
