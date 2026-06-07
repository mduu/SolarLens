#if canImport(ActivityKit)
import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Shared chrome for the Lock Screen / banner Live Activity card.
///
/// Layout: large per-automation glyph anchored on the left so the user
/// can tell automations apart at a glance, title + per-automation body
/// flowing to the right, and a round red Stop button in the top-right
/// corner. The Stop button is intentionally bigger and red — this is
/// a destructive "cancel the automation now" affordance, not the iOS
/// chrome "close" X.
///
/// Live Activity rendering is more restricted than regular SwiftUI:
/// no `Material`, no `TimelineView` at the outer level, no async tasks.
/// The platter background is set via the `.activityBackgroundTint`
/// modifier applied by `AutomationLiveActivity` on the outer view.
struct LockScreenCard: View {
    let context: ActivityViewContext<AutomationLiveActivityAttributes>

    private let cornerRadius: CGFloat = 20

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: context.state.iconSystemName)
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Text(automationTitle)
                        .font(.headline)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    cancelButton
                }
                cardBody(for: context.state)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(LockScreenBorder(cornerRadius: cornerRadius))
    }

    private var cancelButton: some View {
        Button(intent: CancelActiveAutomationIntent()) {
            Image(systemName: "stop.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.red))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cancel automation")
    }

    private var automationTitle: LocalizedStringKey {
        switch context.attributes.automation {
        case .BatteryToCar:
            return "Battery → Car running"
        case .AutoResetChargingMode:
            return "Auto-reset Charging Mode"
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
