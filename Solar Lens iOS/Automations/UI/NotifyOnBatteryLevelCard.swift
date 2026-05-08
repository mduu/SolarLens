import SwiftUI

/// Idle state card for the "Notify on battery level" automation.
struct NotifyOnBatteryLevelCard: View {
    let isOtherActive: Bool
    let isHouseBatteryMissing: Bool
    let onTap: () -> Void

    private var isDisabled: Bool {
        isOtherActive || isHouseBatteryMissing
    }

    private var disabledMessage: LocalizedStringResource? {
        if isHouseBatteryMissing {
            return "Requires a house battery"
        }
        if isOtherActive {
            return "Another automation is active"
        }
        return nil
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(
                        systemName: Automation.NotifyOnBatteryLevel
                            .liveActivityIconSystemName
                    )
                    .font(.title2)
                    Text("Notify on battery level")
                        .font(.headline)
                    Spacer()
                    if !isDisabled {
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .opacity(0.7)
                    }
                }
                Text(
                    "Get a push notification when your house battery reaches a level you choose. Auto-cancels after 24 hours if the level isn't reached."
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
