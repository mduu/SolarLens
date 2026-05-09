import SwiftUI

/// Tiny pulsing icon shown in the OverviewScreen top-right while an
/// automation is running. Tap to jump to the Automations tab.
struct AutomationRunningIndicator: View {
    let activeAutomation: Automation
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: activeAutomation.liveActivityIconSystemName)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(
                    .pulse.wholeSymbol,
                    options: .repeat(.continuous)
                )
                .foregroundStyle(.orange)
                .accessibilityLabel("Automation running")
        }
        .buttonStyle(.plain)
    }
}
