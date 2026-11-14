import SwiftUI

/// The device detail screens — Battery, Charging, Grid — for the iPad.
///
/// With the sidebar open each device is an entry of its own there
/// (`fixed` names it). Collapsed into the tab bar, a sidebar section becomes
/// a single item that only ever shows its first entry, so the tab bar gets
/// one "Devices" item instead (`fixed == nil`) with a picker to move between
/// them. Each variant hands over to the other when the sidebar opens or
/// closes, so the selection always lands on an item that is visible.
struct DevicesScreen: View {
    /// The device this instance always shows, or `nil` for the tab bar's
    /// combined screen.
    var fixed: AppTab?

    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @State private var tabSelection = TabSelection.shared
    @State private var width: CGFloat = 0

    private var available: [AppTab] {
        var result: [AppTab] = []
        if buildingState.overviewData.hasAnyBattery { result.append(.battery) }
        if buildingState.overviewData.hasAnyCarChargingStation { result.append(.charging) }
        result.append(.grid)
        return result
    }

    private var shown: AppTab {
        if let fixed { return fixed }
        return available.contains(tabSelection.lastDevice)
            ? tabSelection.lastDevice : (available.first ?? .grid)
    }

    private var sidebarIsVisible: Bool {
        tabSelection.windowWidth - width > 100
    }

    private var isSelected: Bool {
        tabSelection.selectedTab == (fixed ?? .devices)
    }

    var body: some View {
        @Bindable var tabSelection = tabSelection

        VStack(spacing: 0) {
            if fixed == nil, available.count > 1 {
                Picker("Devices", selection: $tabSelection.lastDevice) {
                    ForEach(available, id: \.self) { device in
                        Text(title(of: device)).tag(device)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 420)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            detail(for: shown)
                .environment(\.detailPlacement, .section)
                .environment(\.detailHidesNavigationBar, fixed == nil)
                .id(shown)
        }
        .background {
            if fixed == nil {
                Color(.systemGroupedBackground).ignoresSafeArea()
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newValue in
            width = newValue
            handOver()
        }
        .onChange(of: tabSelection.windowWidth) { handOver() }
        .onChange(of: isSelected) { handOver() }
    }

    @ViewBuilder
    private func detail(for device: AppTab) -> some View {
        switch device {
        case .battery:
            NavigationStack { BatterySheet() }
        case .charging:
            ChargingModePickerView()
        default:
            NavigationStack { GridSheet() }
        }
    }

    private func title(of device: AppTab) -> LocalizedStringKey {
        switch device {
        case .battery: "Battery"
        case .charging: "Charging"
        default: "Grid"
        }
    }

    /// Moves the selection to the variant the current chrome can show.
    private func handOver() {
        guard isSelected, width > 0, tabSelection.windowWidth > 0 else { return }

        if let fixed {
            tabSelection.lastDevice = fixed
            if !sidebarIsVisible { tabSelection.selectedTab = .devices }
        } else if sidebarIsVisible {
            tabSelection.selectedTab = shown
        }
    }
}
