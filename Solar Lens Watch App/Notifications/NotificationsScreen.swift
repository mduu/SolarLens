import SwiftUI

/// Watch top-level Notifications screen.
///
/// Mirrors the iOS Notifications tab: lists each notification kind,
/// shows it as enabled (with current value + disable button) or idle
/// (tap to open the setup sheet). Enable/update/disable commands are
/// sent to the iPhone via `AutomationWatchSession`; the iPhone is the
/// source of truth.
struct WatchNotificationsScreen: View {
    @Environment(AutomationStateStore.self) private var store
    @Environment(CurrentBuildingState.self) private var buildingState
    @State private var presentedSetupKind: SolarLensNotification?

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    .orange.opacity(0.5), .orange.opacity(0.2),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(SolarLensNotification.allCases, id: \.self) {
                        kind in
                        if isAvailable(kind) {
                            row(for: kind)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
            }
        }
        .sheet(item: $presentedSetupKind) { kind in
            WatchNotificationSetupSheet(
                kind: kind,
                existing: monitor(for: kind)
            )
            .environment(buildingState)
        }
    }

    private var monitors: [NotificationMonitor] {
        store.snapshot?.notifications ?? []
    }

    private func monitor(for kind: SolarLensNotification) -> NotificationMonitor? {
        monitors.first { $0.kind == kind }
    }

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

    @ViewBuilder
    private func row(for kind: SolarLensNotification) -> some View {
        if let m = monitor(for: kind) {
            Button {
                presentedSetupKind = kind
            } label: {
                WatchNotificationRunningRow(
                    monitor: m,
                    onDisable: {
                        AutomationWatchSession.shared
                            .disableNotification(id: m.id)
                    }
                )
            }
            .buttonStyle(.plain)
        } else {
            Button {
                presentedSetupKind = kind
            } label: {
                WatchNotificationIdleRow(kind: kind)
            }
            .buttonStyle(.plain)
        }
    }
}

struct WatchNotificationIdleRow: View {
    let kind: SolarLensNotification

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: kind.iconSystemName)
                .font(.title3)
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: kind.localizedTitleKey))
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Tap to enable")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "plus.circle")
                .foregroundStyle(.tertiary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(.regularMaterial)
        )
        .foregroundStyle(.primary)
    }
}

struct WatchNotificationRunningRow: View {
    let monitor: NotificationMonitor
    let onDisable: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: monitor.kind.iconSystemName)
                .font(.title3)
                .foregroundStyle(.green)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: monitor.kind.localizedTitleKey))
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(thresholdDescription)
                    .font(.caption2.weight(.semibold))
                if let value = monitor.lastValue {
                    Text("Now: \(formatValue(value))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Button(role: .destructive, action: onDisable) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(0.85))
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.green.opacity(0.55), lineWidth: 1.5)
        )
        .foregroundStyle(.primary)
    }

    private var thresholdDescription: String {
        let comparator: String
        switch monitor.comparison {
        case .equalOrAbove: comparator = "≥"
        case .equalOrBelow: comparator = "≤"
        }
        return "\(comparator) \(formatValue(monitor.threshold))"
    }

    private func formatValue(_ value: Int) -> String {
        if monitor.kind.isPercent { return "\(value)%" }
        return String(format: "%.1f kW", Double(value) / 1000.0)
    }
}
