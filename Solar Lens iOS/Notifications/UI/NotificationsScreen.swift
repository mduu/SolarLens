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
    @State private var history = NotificationHistoryManager.shared
    @State private var presentedSetupKind: SolarLensNotification?
    @State private var historySheetPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    // Two-column grid so more kinds fit above the fold.
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible()),
                        ],
                        spacing: 12
                    ) {
                        ForEach(SolarLensNotification.allCases, id: \.self) {
                            kind in
                            if isAvailable(kind) {
                                row(for: kind)
                            }
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        historySheetPresented = true
                    } label: {
                        // The badge must stay within the label's bounds —
                        // toolbar items clip overflowing content. So we
                        // reserve space around the icon (constant, to keep
                        // the icon from shifting when the badge appears)
                        // and place the badge inside it.
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "clock.arrow.circlepath")
                                .padding(.top, 5)
                                .padding(.trailing, 9)
                            if history.unreadCount > 0 {
                                Text("\(history.unreadCount)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(.red))
                            }
                        }
                    }
                    .accessibilityLabel("Show notification history")
                    .foregroundStyle(.secondary)
                }
            }
            .sheet(item: $presentedSetupKind) { kind in
                NotificationSetupSheet(
                    kind: kind,
                    existing: manager.monitor(for: kind)
                )
            }
            .sheet(isPresented: $historySheetPresented) {
                NotificationHistoryView()
            }
        }
    }

    /// Kept deliberately compact (footnote text, tight spacing) — the
    /// header is explanatory chrome and shouldn't push the actual
    /// notification rows below the fold.
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge")
                Text("Stay informed")
                    .font(.headline)
            }
            Text(
                "Get a notification when battery, solar, grid or charging crosses a level you choose. Run several in parallel."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(12)
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
