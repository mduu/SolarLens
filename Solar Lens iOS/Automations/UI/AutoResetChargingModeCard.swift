import SwiftUI

/// Idle state card for the "Auto-reset Charging Mode" automation.
struct AutoResetChargingModeCard: View {
    let isOtherActive: Bool
    let isChargingStationMissing: Bool
    let onTap: () -> Void

    private var isDisabled: Bool {
        isOtherActive || isChargingStationMissing
    }

    private var disabledMessage: LocalizedStringResource? {
        if isChargingStationMissing {
            return "Requires a charging station"
        }
        if isOtherActive {
            return "Another automation is active"
        }
        return nil
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                Image(
                    systemName: Automation.AutoResetChargingMode
                        .liveActivityIconSystemName
                )
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Auto-reset Charging Mode")
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    Text(
                        "Set a charging mode now and let Solar Lens automatically switch back to another mode at a date and time you choose."
                    )
                    .font(.callout)
                    .multilineTextAlignment(.leading)

                    if let msg = disabledMessage {
                        Label(msg, systemImage: "info.circle")
                            .font(.footnote)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.primary)
            .background(
                AICardBackground(
                    isAnimating: false,
                    opacity: isDisabled ? 0.45 : 0.85
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
