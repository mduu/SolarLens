import SwiftUI

/// Automations and notifications side by side. Used where the window is wide
/// enough that either screen alone would leave half of it empty.
struct AutomationHubScreen: View {
    var body: some View {
        HStack(spacing: 0) {
            AutomationScreen()
            Divider()
            NotificationsScreen()
        }
    }
}

#Preview {
    AutomationHubScreen()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()
            )
        )
}
