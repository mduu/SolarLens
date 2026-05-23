import SwiftUI

/// Watch running card for the Auto-reset Charging Mode automation.
struct AutoResetChargingModeRunningCard: View {
    let state: AutomationAutoResetChargingModeState
    let params: AutomationAutoResetChargingModeParameters
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "timer.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
                    .font(.title3)
                Text("Auto-reset Mode")
                    .font(.headline)
                    .lineLimit(1)
            }

            HStack(spacing: 4) {
                Text(params.activeChargingMode.localizedTitle)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(params.afterResetChargingMode.localizedTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if params.resetAt > Date() {
                HStack(spacing: 4) {
                    Image(systemName: "hourglass")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(
                        timerInterval: Date()...params.resetAt,
                        countsDown: true
                    )
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
