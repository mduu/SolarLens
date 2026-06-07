#if canImport(ActivityKit)
import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Per-region builders for the Dynamic Island. Compact, minimal and the
/// expanded leading region all show the **per-automation** SF Symbol
/// (`state.iconSystemName`) painted with the Solar Lens brand gradient
/// — this gives the user immediate "which automation is running" cues
/// while still reading as Solar Lens at a glance.
///
/// We tried using the app icon image (`Image("LogoMark")`) here but the
/// Live Activity render context kept silhouetting it into a flat
/// tinted template — see git history for the back-and-forth. SF Symbols
/// render reliably in this context.
enum DynamicIslandLayouts {

    @ViewBuilder
    static func leading(
        _ state: AutomationLiveActivityAttributes.ContentState
    ) -> some View {
        Image(systemName: state.iconSystemName)
            .foregroundStyle(AutomationBrand.titleGradient)
            .font(.title3)
            .padding(.leading, 4)
    }

    static func trailingCancelButton() -> some View {
        Button(intent: CancelActiveAutomationIntent()) {
            Image(systemName: "stop.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.red))
        }
        .buttonStyle(.plain)
        .padding(.trailing, 4)
        .accessibilityLabel("Cancel automation")
    }

    @ViewBuilder
    static func expandedBody(
        state: AutomationLiveActivityAttributes.ContentState
    ) -> some View {
        switch state.payload {
        case .batteryToCar(let payload):
            BatteryToCarCardBody(
                payload: payload,
                primaryMetric: state.primaryMetric,
                startedAt: state.startedAt,
                compact: true
            )
            .padding(.horizontal, 4)
            .padding(.top, 2)
        case .autoResetChargingMode(let payload):
            AutoResetChargingModeCardBody(
                payload: payload,
                compact: true
            )
            .padding(.horizontal, 4)
            .padding(.top, 2)
        }
    }

    /// Compact-leading: per-automation SF Symbol with brand-gradient tint.
    static func compactLeading(
        _ state: AutomationLiveActivityAttributes.ContentState
    ) -> some View {
        Image(systemName: state.iconSystemName)
            .foregroundStyle(AutomationBrand.titleGradient)
    }

    /// Compact-trailing: the primary live metric. For Battery → Car this
    /// is the kWh transferred (a snapshot string). For Auto-reset
    /// Charging Mode this is a live `Text(timerInterval:)` countdown so
    /// the Dynamic Island ticks down once per second without our app
    /// being involved.
    @ViewBuilder
    static func compactTrailing(
        _ state: AutomationLiveActivityAttributes.ContentState
    ) -> some View {
        switch state.payload {
        case .autoResetChargingMode(let payload) where payload.resetAt > Date():
            Text(
                timerInterval: Date()...payload.resetAt,
                countsDown: true
            )
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.primary)
        default:
            Text(state.primaryMetric.value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }

    /// Minimal: shown when other Live Activities are also active.
    static func minimal(
        _ state: AutomationLiveActivityAttributes.ContentState
    ) -> some View {
        Image(systemName: state.iconSystemName)
            .foregroundStyle(AutomationBrand.titleGradient)
    }
}
#endif
