import SwiftUI

/// Diagnostic log viewer for the automation runner. Hidden behind a
/// subtle toolbar entry on the Automation screen — primarily intended
/// for tech-savvy users and for the developer when debugging
/// background-runtime quirks (BG task gaps, expirations, etc.).
struct AutomationLogView: View {
    @State private var messages: [AutomationLogMessage] =
        AutomationLogManager.shared.load()
    @State private var selectedLevels: Set<AutomationLogMessageLevel> = Set(
        AutomationLogMessageLevel.defaultCases
    )
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var hasActiveFilter: Bool {
        !searchText.isEmpty
            || selectedLevels
                != Set(AutomationLogMessageLevel.allCases)
    }

    private var filteredMessages: [AutomationLogMessage] {
        messages
            .filter { selectedLevels.contains($0.level) }
            .filter { message in
                searchText.isEmpty
                    || String(localized: message.message)
                        .localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.time > $1.time }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                Divider()

                if filteredMessages.isEmpty {
                    emptyState
                } else {
                    List(filteredMessages) { message in
                        AutomationLogRowView(message: message)
                            .listRowSeparator(.hidden)
                            .listRowInsets(
                                .init(
                                    top: 6, leading: 16,
                                    bottom: 6, trailing: 16
                                )
                            )
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search logs…")
            .navigationTitle("Automation Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            UIPasteboard.general.string = exportText()
                        } label: {
                            if hasActiveFilter {
                                Label(
                                    "Copy filtered",
                                    systemImage: "doc.on.doc"
                                )
                            } else {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                        ShareLink(
                            item: exportText(),
                            preview: SharePreview("Automation logs")
                        ) {
                            if hasActiveFilter {
                                Label(
                                    "Share filtered…",
                                    systemImage: "square.and.arrow.up"
                                )
                            } else {
                                Label(
                                    "Share…",
                                    systemImage: "square.and.arrow.up"
                                )
                            }
                        }
                        Divider()
                        Button(role: .destructive) {
                            withAnimation {
                                AutomationLogManager.shared.clearAll()
                                messages = []
                            }
                        } label: {
                            Label("Clear log", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .automationLogAdded
                )
            ) { _ in
                messages = AutomationLogManager.shared.load()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .automationLogCleared
                )
            ) { _ in
                messages = []
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(
                    AutomationLogMessageLevel.allCases, id: \.self
                ) { level in
                    let count = messages.filter { $0.level == level }.count
                    FilterButton(
                        level: level,
                        count: count,
                        isSelected: selectedLevels.contains(level)
                    ) {
                        toggleLevel(level)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.secondary)
            Text(messages.isEmpty ? "No log entries yet" : "No matches")
                .font(.headline)
                .foregroundStyle(.secondary)
            if !messages.isEmpty && !searchText.isEmpty {
                Text("Try a different search or filter.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func toggleLevel(_ level: AutomationLogMessageLevel) {
        if selectedLevels.contains(level) {
            selectedLevels.remove(level)
        } else {
            selectedLevels.insert(level)
        }
    }

    private func exportText() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return filteredMessages
            .sorted { $0.time < $1.time }
            .map {
                let ts = formatter.string(from: $0.time)
                let lvl = $0.level.displayName.uppercased()
                let msg = String(localized: $0.message)
                return "\(ts) [\(lvl)] \(msg)"
            }
            .joined(separator: "\n")
    }
}

private struct FilterButton: View {
    let level: AutomationLogMessageLevel
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: level.symbolName)
                    .font(.system(size: 12, weight: .semibold))
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.monospacedDigit())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? level.color.opacity(0.18)
                            : Color.gray.opacity(0.10)
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected
                            ? level.color
                            : Color.gray.opacity(0.30),
                        lineWidth: 1
                    )
            )
        }
        .foregroundStyle(isSelected ? level.color : Color.secondary)
        .accessibilityLabel(
            "\(level.displayName), \(count) entries, \(isSelected ? "shown" : "hidden")"
        )
    }
}

struct AutomationLogRowView: View {
    let message: AutomationLogMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: message.level.symbolName)
                .foregroundStyle(message.level.color)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 18)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(message.message)
                    .font(.callout)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(
                    message.time,
                    format: .dateTime
                        .day(.twoDigits)
                        .month(.twoDigits)
                        .hour(.twoDigits(amPM: .omitted))
                        .minute(.twoDigits)
                        .second(.twoDigits)
                )
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button {
                UIPasteboard.general.string =
                    String(localized: message.message)
            } label: {
                Label("Copy message", systemImage: "doc.on.doc")
            }
        }
    }
}

#Preview {
    AutomationLogView()
}
