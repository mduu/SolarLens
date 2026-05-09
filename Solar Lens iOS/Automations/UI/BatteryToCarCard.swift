import SwiftUI

/// Idle state card for the "Transfer from Battery to Car" automation.
///
/// Layout: large per-automation glyph anchored on the left in a solid
/// brand colour, text content (title, description, optional disabled
/// hint) flowing to the right. Same shape across all automations so
/// they read as a coherent set.
struct BatteryToCarCard: View {
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
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "bolt.car.circle.fill")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Transfer from Battery to Car")
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    Text(
                        "Transfer energy from your house battery to your car. Stops automatically before the battery gets too low."
                    )
                    .font(.footnote)
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
