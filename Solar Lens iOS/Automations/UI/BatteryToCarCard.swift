import SwiftUI

/// Idle state card for the "Transfer from Battery to Car" automation.
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
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.car.fill")
                        .font(.title2)
                    Text("Transfer from Battery to Car")
                        .font(.headline)
                    Spacer()
                    if !isDisabled {
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .opacity(0.7)
                    }
                }
                Text(
                    "Transfer energy from your house battery to your car. Stops automatically before the battery gets too low."
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
            .foregroundStyle(.white)
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
        BatteryToCarCard(
            isOtherActive: false,
            isHouseBatteryMissing: false,
            onTap: {}
        )
        BatteryToCarCard(
            isOtherActive: true,
            isHouseBatteryMissing: false,
            onTap: {}
        )
        BatteryToCarCard(
            isOtherActive: false,
            isHouseBatteryMissing: true,
            onTap: {}
        )
    }
    .padding()
}
