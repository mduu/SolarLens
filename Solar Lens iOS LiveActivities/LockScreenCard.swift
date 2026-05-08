#if canImport(ActivityKit)
import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Shared chrome for the Lock Screen / banner Live Activity card.
///
/// Composes the brand identity (sparkles + title gradient + brand border),
/// exposes a Cancel button, and slots a per-automation body picked from
/// the `Payload` case — never knows about specific automations beyond that
/// switch.
///
/// Live Activity rendering is more restricted than regular SwiftUI:
/// no `Material`, no `TimelineView` at the outer level, no async tasks.
/// The platter background is set via the `.activityBackgroundTint` modifier
/// applied by `AutomationLiveActivity` on the outer view.
struct LockScreenCard: View {
    let context: ActivityViewContext<AutomationLiveActivityAttributes>

    private let cornerRadius: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: context.state.iconSystemName)
                    .foregroundStyle(AutomationBrand.titleGradient)
                    .font(.title3)
                Text(automationTitle)
                    .font(.headline)
                Spacer()
                Button(intent: CancelActiveAutomationIntent()) {
                    Label("Cancel", systemImage: "stop.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.85))
            }

            cardBody(for: context.state)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(LockScreenBorder(cornerRadius: cornerRadius))
    }

    private var automationTitle: LocalizedStringKey {
        switch context.attributes.automation {
        case .BatteryToCar:
            return "Battery → Car running"
        case .AutoResetChargingMode:
            return "Auto-reset Charging Mode"
        case .NotifyOnBatteryLevel:
            return "Notify on battery level"
        }
    }

    @ViewBuilder
    private func cardBody(
        for state: AutomationLiveActivityAttributes.ContentState
    ) -> some View {
        switch state.payload {
        case .batteryToCar(let payload):
            BatteryToCarCardBody(
                payload: payload,
                primaryMetric: state.primaryMetric,
                startedAt: state.startedAt
            )
        case .autoResetChargingMode(let payload):
            AutoResetChargingModeCardBody(payload: payload)
        case .notifyOnBatteryLevel(let payload):
            NotifyOnBatteryLevelCardBody(payload: payload)
        }
    }
}

/// Static brand border for the Lock Screen card. Live Activity rendering
/// snapshots the view, so animations would only show the captured frame —
/// using a static gradient is honest about the constraint.
private struct LockScreenBorder: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
                AngularGradient(
                    colors: AutomationBrand.angularGradientColors,
                    center: .center,
                    angle: .degrees(45)
                ),
                lineWidth: 3
            )
    }
}
#endif
