import SwiftUI

/// Watch running card for the Battery → Car automation.
/// Compact single-column layout: title row, two-line metrics, optional
/// ETA, and a destructive Stop button.
struct BatteryToCarRunningCard: View {
    let state: AutomationBatteryToCarState
    let params: AutomationBatteryToCarParameters
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.car.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
                    .font(.title3)
                Text("Battery → Car")
                    .font(.headline)
                    .lineLimit(1)
            }

            HStack(spacing: 4) {
                Text("\(state.lastBatteryPercentage ?? state.startSoc)%")
                    .monospacedDigit()
                    .font(.caption.weight(.semibold))
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(params.minBatteryLevel)%")
                    .monospacedDigit()
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 6) {
                Text("\(state.currentAmps) A")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("·")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.2f kWh", state.kWhTransferred))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let rate = BatteryRateFormatter.format(
                rateW: state.lastBatteryChargeRate
            ) {
                Text(rate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            forecastRow(eta: state.forecastedFloorAt)

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

    @ViewBuilder
    private func forecastRow(eta: Date?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Floor reached in")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let eta, eta > Date() {
                Text(timerInterval: Date()...eta, countsDown: true)
                    .monospacedDigit()
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            } else {
                Text("—")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
