#if canImport(ActivityKit)
import ActivityKit
import SwiftUI
import WidgetKit

/// Root `ActivityConfiguration` that ActivityKit shows on the Lock Screen
/// and in the Dynamic Island for any Solar Lens automation.
///
/// Open for extension: this file never needs editing when adding a new
/// automation. Per-automation richness comes through
/// `AutomationLiveActivityAttributes.ContentState.Payload`, which is
/// switched on inside `LockScreenCard` and `DynamicIslandLayouts`.
struct AutomationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(
            for: AutomationLiveActivityAttributes.self
        ) { context in
            // Lock Screen / banner.
            // We force a near-opaque dark backdrop in both light and dark
            // mode so the card always reads with the same Solar-Lens look
            // (yellow/white/orange brand stops on dark) — without this the
            // light-mode platter is a translucent grey that loses
            // contrast against bright wallpapers.
            LockScreenCard(context: context)
                .environment(\.colorScheme, .dark)
                .activityBackgroundTint(
                    Color(red: 0.07, green: 0.10, blue: 0.16)
                )
                .activitySystemActionForegroundColor(.white)
                .widgetURL(URL(string: "solarlens://automation"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    DynamicIslandLayouts.leading(context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    DynamicIslandLayouts.trailingCancelButton()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    DynamicIslandLayouts.expandedBody(state: context.state)
                }
            } compactLeading: {
                DynamicIslandLayouts.compactLeading(context.state)
            } compactTrailing: {
                DynamicIslandLayouts.compactTrailing(context.state)
            } minimal: {
                DynamicIslandLayouts.minimal(context.state)
            }
            .widgetURL(URL(string: "solarlens://automation"))
            .keylineTint(.yellow)
        }
    }
}
#endif
