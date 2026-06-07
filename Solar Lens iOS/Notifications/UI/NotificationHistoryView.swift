import SwiftUI

/// History of fired notifications (= delivered local pushes), grouped
/// per day with the newest entries first. Reached via the toolbar entry
/// on the Notifications screen — the counterpart to `AutomationLogView`
/// on the Automation tab, but user-facing: one row per delivered
/// notification instead of a diagnostic log stream.
///
/// Opening the sheet marks every entry as read, which clears the unread
/// badges (toolbar button + tab bar).
struct NotificationHistoryView: View {
    @State private var events: [NotificationFiredEvent] =
        NotificationHistoryManager.shared.load()
    @Environment(\.dismiss) private var dismiss

    /// Events bucketed by calendar day, newest day (and newest entry
    /// within each day) first.
    private var groupedByDay: [(day: Date, events: [NotificationFiredEvent])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: events) {
            calendar.startOfDay(for: $0.time)
        }
        return groups.keys.sorted(by: >).map { day in
            (day: day, events: groups[day]!.sorted { $0.time > $1.time })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(groupedByDay, id: \.day) { group in
                            Section(dayTitle(for: group.day)) {
                                ForEach(group.events) { event in
                                    NotificationHistoryRow(event: event)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(
                                            .init(
                                                top: 6, leading: 16,
                                                bottom: 6, trailing: 16
                                            )
                                        )
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notification history")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            withAnimation {
                                NotificationHistoryManager.shared.clearAll()
                                events = []
                            }
                        } label: {
                            Label("Clear history", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                NotificationHistoryManager.shared.markAllRead()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .notificationHistoryAdded
                )
            ) { _ in
                events = NotificationHistoryManager.shared.load()
                // The sheet is open, so the user sees the new entry
                // immediately — keep the badges clear.
                NotificationHistoryManager.shared.markAllRead()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .notificationHistoryCleared
                )
            ) { _ in
                events = []
            }
        }
    }

    /// "Today" for the current day, otherwise an explicit `31.12.2025`
    /// style date (deliberately fixed format, not locale-driven).
    private func dayTitle(for day: Date) -> String {
        if Calendar.current.isDateInToday(day) {
            return String(localized: "Today")
        }
        return Self.dayFormatter.string(from: day)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.slash")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.secondary)
            Text("No notifications fired yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Once a notification fires, it shows up here.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct NotificationHistoryRow: View {
    let event: NotificationFiredEvent

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: event.kind.iconSystemName)
                .foregroundStyle(.green)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 22)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(String(localized: event.kind.localizedTitleKey))
                        .font(.callout.weight(.semibold))
                    Spacer(minLength: 8)
                    Text(
                        event.time,
                        format: .dateTime
                            .hour(.twoDigits(amPM: .omitted))
                            .minute(.twoDigits)
                    )
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                }
                Text(detailText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    /// Mirrors the delivered push's body line ("Current X (target ≥ Y).")
    /// so the history reads like the notifications the user received.
    private var detailText: String {
        let comparator: String
        switch event.comparison {
        case .equalOrAbove: comparator = "≥"
        case .equalOrBelow: comparator = "≤"
        }
        let valueText = formatValue(event.value)
        let thresholdText = formatValue(event.threshold)
        return String(
            localized:
                "Current \(valueText) (target \(comparator) \(thresholdText))."
        )
    }

    private func formatValue(_ value: Int) -> String {
        if event.kind.isPercent {
            return "\(value)%"
        }
        return String(format: "%.1f kW", Double(value) / 1000.0)
    }
}

#Preview {
    NotificationHistoryView()
}
