import SwiftUI

/// Idle state card for the "Auto-reset Charging Mode" automation.
struct AutoResetChargingModeCard: View {
    let isOtherActive: Bool
    let onTap: () -> Void

    private var isDisabled: Bool {
        isOtherActive
    }

    private var disabledMessage: LocalizedStringResource? {
        isOtherActive ? "Another automation is active" : nil
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(
                        systemName: Automation.AutoResetChargingMode
                            .liveActivityIconSystemName
                    )
                    .font(.title2)
                    Text("Auto-reset Charging Mode")
                        .font(.headline)
                    Spacer()
                    if !isDisabled {
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .opacity(0.7)
                    }
                }
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

#Preview {
    VStack(spacing: 12) {
        AutoResetChargingModeCard(
            isOtherActive: false,
            onTap: {}
        )
        AutoResetChargingModeCard(
            isOtherActive: true,
            onTap: {}
        )
    }
    .padding()
}
