import SwiftUI

/// The detail beside the dashboard: whatever tile was tapped last, shown in
/// the same view its sheet uses on the iPhone.
struct HomeDetailPane: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    let router: HomeDetailRouter

    var body: some View {
        VStack(spacing: 0) {
            header

            detail
        }
        .background(.regularMaterial)
    }

    /// The pane's own title bar. The detail views' navigation bars cannot do
    /// this job here: with the tab bar across the top of the screen, iPadOS
    /// clears every navigation bar's centre for the tabs — the title vanishes
    /// and the close button moves into a "…" menu.
    private var header: some View {
        ZStack {
            Text(title)
                .font(.headline)

            HStack {
                Button {
                    router.close()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .contentShape(.rect)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(.secondary)
                .accessibilityLabel("Close")
                .keyboardShortcut(.cancelAction)

                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var title: LocalizedStringKey {
        switch router.detail {
        case .production: "Solar Production"
        case .grid: "Grid"
        case .battery: "Battery"
        case .consumption: "Consumption"
        case .charging: "Charging"
        case .efficiency: "Efficiency"
        case nil: ""
        }
    }

    private var detail: some View {
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
        .environment(\.detailHidesNavigationBar, true)
    }
}
