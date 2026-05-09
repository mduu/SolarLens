import SwiftUI

/// Watch running card for the Notify on Battery Level automation.
struct NotifyOnBatteryLevelRunningCard: View {
    let state: AutomationNotifyOnBatteryLevelState
    let params: AutomationNotifyOnBatteryLevelParameters
    let onCancel: () -> Void

    private var comparator: String {
        switch params.comparison {
        case .equalOrAbove: return "≥"
        case .equalOrBelow: return "≤"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "bell.badge.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
                    .font(.title3)
                Text("Battery Alert")
                    .font(.headline)
                    .lineLimit(1)
            }

            HStack(spacing: 4) {
                if let lvl = state.lastBatteryLevel {
                    Text("\(lvl)%")
                        .monospacedDigit()
                        .font(.caption.weight(.semibold))
                }
                Spacer()
                Text("\(comparator) \(params.targetBatteryLevel)%")
                    .monospacedDigit()
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if let eta = state.forecastedTargetAt, eta > Date() {
                HStack(spacing: 4) {
                    Image(systemName: "hourglass")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(timerInterval: Date()...eta, countsDown: true)
                        .monospacedDigit()
                        .font(.caption2)
                        .foregroundStyle(.primary)
                }
            }

            Button(role: .destructive, action: onCancel) {
                Label("Stop", systemImage: "stop.circle.fill")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.small)
            .tint(.red)
            .padding(.top, 2)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.orange.opacity(0.6), lineWidth: 1.5)
        )
    }
}
