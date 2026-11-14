import SwiftUI

/// The detail beside the dashboard: whatever tile was tapped last, shown in
/// the same view its sheet uses on the iPhone.
struct HomeDetailPane: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    let router: HomeDetailRouter

    var body: some View {
        Group {
            switch router.detail {
            case .production:
                NavigationStack { TodayChartSheet() }
            case .grid:
                NavigationStack { GridSheet() }
            case .battery:
                NavigationStack { BatterySheet() }
            case .consumption:
                NavigationStack {
                    DevicePrioritySheet(
                        pinnedConfig: router.pinnedConfig ?? PinnedDevicesConfiguration()
                    )
                }
            case .charging:
                ChargingModePickerView()
            case .efficiency:
                EfficiencySheet(hasAnyBattery: buildingState.overviewData.hasAnyBattery)
            case nil:
                EmptyView()
            }
        }
        // One pane, several details: without an identity SwiftUI would keep
        // the previous detail's navigation state when the tile changes.
        .id(router.detail)
        .environment(\.closeDetail) { router.close() }
        .environment(\.detailPlacement, .pane)
    }
}
