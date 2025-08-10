//

import SwiftUI

struct ScenarioLogView: View {
    @State var messages: [ScenarioLogMessage] = ScenarioLogManager.shared.load()
    @State private var selectedLevels: Set<ScenarioLogMessageLevel> = Set(
        ScenarioLogMessageLevel.defaultCases
    )
    @State private var searchText = ""

    private var filteredMessages: [ScenarioLogMessage] {
        messages
            .filter { selectedLevels.contains($0.level) }
            .filter { message in
                searchText.isEmpty
                    || String(localized: message.message)
                        .localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.time > $1.time }  // Most recent first
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ScenarioLogMessageLevel.allCases, id: \.self) {
                            level in
                            FilterButton(
                                level: level,
                                isSelected: selectedLevels.contains(level)
                            ) {
                                toggleLevel(level)
                            }
                        }

                        Divider()
                            .frame(maxHeight: 30)

                        // Clear log button
                        Button(action: {
                            withAnimation {
                                ScenarioLogManager.shared.clearAll()
                                messages = ScenarioLogManager.shared.load()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3),lineWidth: 1)
                            )
                        }
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                Divider()

                // Log list
                List(filteredMessages, id: \.time) { message in
                    ScenarioLogRowView(message: message)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search logs...")
            }
            .navigationTitle("Scenario Logs")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func toggleLevel(_ level: ScenarioLogMessageLevel) {
        if selectedLevels.contains(level) {
            selectedLevels.remove(level)
        } else {
            selectedLevels.insert(level)
        }
    }
}

struct FilterButton: View {
    let level: ScenarioLogMessageLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: level.symbolName)
                    .font(.system(size: 12, weight: .medium))

                /*
                Text(level.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                 */
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected
                            ? level.color.opacity(0.2) : Color.gray.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? level.color : Color.gray.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .foregroundColor(isSelected ? level.color : .secondary)
    }
}

struct ScenarioLogRowView: View {
    let message: ScenarioLogMessage

    var body: some View {
        HStack(spacing: 8) {
            // Level indicator
            Image(systemName: message.level.symbolName)
                .foregroundColor(message.level.color)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 16)

            // Timestamp
            Text(message.time, format: .dateTime.hour().minute().second())
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            // Message
            Text(message.message)
                .font(.body)
                .lineLimit(nil)

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ScenarioLogView(
        messages: [
            .init(
                time: Date().addingTimeInterval(-7200),
                message: "Testing Debug",
                level: .Debug
            ),
            .init(
                time: Date().addingTimeInterval(-3600),
                message: "Testing Info",
                level: .Info
            ),
            .init(
                time: Date().addingTimeInterval(-3500),
                message: "Testing Sucess",
                level: .Success
            ),
            .init(
                time: Date().addingTimeInterval(-3200),
                message: "Testing Error",
                level: .Error
            ),
            .init(
                time: Date(),
                message: "Testing Failure",
                level: .Failure
            ),
        ]
    )
}
