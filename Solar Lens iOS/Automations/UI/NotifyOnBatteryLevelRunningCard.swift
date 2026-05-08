import SwiftUI

/// Live state card while the "Notify on battery level" automation is
/// running. Shows the most recent battery reading, the user's chosen
/// threshold, and elapsed time.
struct NotifyOnBatteryLevelRunningCard: View {
    let state: AutomationNotifyOnBatteryLevelState
    let params: AutomationNotifyOnBatteryLevelParameters
    let onCancel: () -> Void

    private let cornerRadius: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: AutomationBrand.accentSymbol)
                    .foregroundStyle(.primary)
                Text("Notify on battery level")
                    .font(.headline)
                Spacer()
                HStack(spacing: 5) {
                    Image(
                        systemName: Automation.NotifyOnBatteryLevel
                            .liveActivityIconSystemName
                    )
                    .symbolEffect(.pulse, options: .repeating)
                    .symbolRenderingMode(.monochrome)
                    Text("Running")
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color(red: 0.13, green: 0.66, blue: 0.32))
                )
                .foregroundStyle(.white)
            }

            HStack(spacing: 24) {
                metric(
                    label: "Battery",
                    value: state.lastBatteryLevel.map { "\($0)%" } ?? "—"
                )
                metric(
                    label: "Target",
                    value: "\(comparator) \(params.targetBatteryLevel)%"
                )
                if let started = state.startedAt {
                    metric(label: "Running for", value: elapsed(since: started))
                }
            }

            Button(role: .destructive, action: onCancel) {
                Label("Cancel automation", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red.opacity(0.85))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.regularMaterial)
        )
        .overlay(
            AICardBorder(
                cornerRadius: cornerRadius,
                lineWidth: 5
            )
        )
        .background(
            AICardGlow(cornerRadius: cornerRadius)
                .padding(-6)
        )
    }

    private var comparator: String {
        switch params.comparison {
        case .equalOrAbove: return "≥"
        case .equalOrBelow: return "≤"
        }
    }

    private func elapsed(since start: Date) -> String {
        let secs = max(0, Int(Date().timeIntervalSince(start)))
        let m = secs / 60
        if m < 1 { return "<1m" }
        if m < 60 { return "\(m)m" }
        let h = m / 60
        let rem = m % 60
        return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
    }

    private func metric(
        label: LocalizedStringKey, value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}
