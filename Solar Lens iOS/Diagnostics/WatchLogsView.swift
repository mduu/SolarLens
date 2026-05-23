import SwiftUI

/// Lists activity logs shipped from the watch via "Send to iPhone".
/// Each row is tappable to read inline; toolbar offers Share (system
/// activity sheet) and a destructive "Clear all" action.
struct WatchLogsView: View {
    @State private var files: [URL] = []
    @State private var selected: URL?
    @State private var showClearAllConfirm = false

    var body: some View {
        List {
            if files.isEmpty {
                Section {
                    Text(
                        "No logs received yet. On your Apple Watch, open the Solar Lens app → gear icon → Activity log → Send to iPhone."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(files, id: \.self) { url in
                        Button {
                            selected = url
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(displayName(for: url))
                                        .font(.body)
                                    Text(sizeDescription(for: url))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) {
                                WatchLogsStore.shared.delete(url)
                                reload()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Activity log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !files.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showClearAllConfirm = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete all received watch logs?",
            isPresented: $showClearAllConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete all", role: .destructive) {
                WatchLogsStore.shared.deleteAll()
                reload()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $selected) { url in
            NavigationStack {
                WatchLogDetailView(url: url)
            }
        }
        .onAppear { reload() }
    }

    private func reload() {
        files = WatchLogsStore.shared.allFiles()
    }

    private func displayName(for url: URL) -> String {
        // Filename pattern: "watch-diagnostics-<unix-ts>.log".
        let stem = url.deletingPathExtension().lastPathComponent
        if let tsString = stem.split(separator: "-").last,
            let ts = TimeInterval(tsString)
        {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .medium
            return df.string(from: Date(timeIntervalSince1970: ts))
        }
        return url.lastPathComponent
    }

    private func sizeDescription(for url: URL) -> String {
        let bytes =
            (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let kb = Double(bytes) / 1024.0
        return String(format: "%.1f KB", kb)
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

private struct WatchLogDetailView: View {
    let url: URL

    @Environment(\.dismiss) private var dismiss
    @State private var content: String = ""
    @State private var showShare = false

    var body: some View {
        ScrollView {
            Text(content.isEmpty ? "(empty)" : content)
                .font(.system(size: 11, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(url.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onAppear {
            content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        }
    }
}
