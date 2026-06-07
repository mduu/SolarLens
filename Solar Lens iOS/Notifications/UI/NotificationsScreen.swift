import SwiftUI

/// Top-level "Notifications" tab.
///
/// Lists every notification kind the user can enable. An enabled
/// notification renders as an "active" row (green tint, live value,
/// disable button). A disabled notification renders as an idle row
/// (tap to open the setup sheet for that kind). Multiple notifications
/// can be enabled simultaneously — see [ADR-002](../../specs/adrs/002-notifications-separate-from-automations.md).
struct NotificationsScreen: View {
    @Environment(CurrentBuildingState.self) private var buildingState
    @State private var manager = NotificationManager.shared
    @State private var presentedSetupKind: SolarLensNotification?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    ForEach(SolarLensNotification.allCases, id: \.self) {
                        kind in
                        if isAvailable(kind) {
                            row(for: kind)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Notifications")
                        .font(.title2.weight(.bold))
                }
            }
            .sheet(item: $presentedSetupKind) { kind in
                NotificationSetupSheet(
                    kind: kind,
                    existing: manager.monitor(for: kind)
                )
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge")
                Text("Stay informed")
                    .font(.headline)
            }
            Text(
                "Get a notification when battery, solar, grid or charging crosses a level you choose. Run several in parallel."
            )
            .font(.callout)
            .foregroundStyle(.secondary)

            Label(
                "Keep Solar Lens open for the most precise timing.",
                systemImage: "info.circle"
            )
            .font(.caption)
            .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(.regularMaterial)
        )
    }

    @ViewBuilder
    private func row(for kind: SolarLensNotification) -> some View {
        if let monitor = manager.monitor(for: kind) {
            NotificationRunningRow(
                monitor: monitor,
                onDisable: { manager.disable(id: monitor.id) },
                onEdit: { presentedSetupKind = kind }
            )
        } else {
            NotificationIdleRow(
                kind: kind,
                onTap: { presentedSetupKind = kind }
            )
        }
    }

    /// Hides notification kinds whose underlying metric isn't available
    /// on this user's installation (no battery → hide BatteryLevel; no
    /// charging station → hide ChargingThroughput). Grid & solar are
    /// always meaningful.
    private func isAvailable(_ kind: SolarLensNotification) -> Bool {
        let overview = buildingState.overviewData
        switch kind {
        case .BatteryLevel:        return overview.hasAnyBattery
        case .ChargingThroughput:  return overview.hasAnyCarChargingStation
        case .SolarProduction, .GridExport, .GridImport,
            .OverallConsumption:
            return true
        }
    }
}

#Preview {
    NotificationsScreen()
        .environment(CurrentBuildingState(
            energyManagerClient: FakeEnergyManager()
        ))
}
