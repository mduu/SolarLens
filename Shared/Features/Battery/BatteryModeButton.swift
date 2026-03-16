import SwiftUI

struct BatteryModeButton: View {
    let battery: Device
    let mode: BatteryMode

    @State var showBatteryModeOptions = false
    @Environment(\.colorScheme) private var colorScheme

    private var isSelected: Bool {
        battery.batteryInfo?.modeInfo.batteryMode == mode
    }

    private var accentColor: Color { .purple }

    var body: some View {
        Button(action: {
            showBatteryModeOptions = true
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(isSelected ? 0.2 : 0.08))
                        .frame(width: 36, height: 36)
                    modeIcon(for: mode)
                        .font(.system(size: 16))
                        .foregroundStyle(accentColor)
                }

                Text(mode.GetBatteryModeName())
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected
                          ? accentColor.opacity(colorScheme == .dark ? 0.12 : 0.08)
                          : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? accentColor.opacity(0.4) : Color.primary.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        #if os(watchOS)
        .sheet(
            isPresented: $showBatteryModeOptions) {

            BatteryModeOptionsSheet(
                battery: battery,
                targetMode: mode
            )
        }
        #else
            .sheet(isPresented: $showBatteryModeOptions) {

                NavigationView {

                    BatteryModeOptionsSheet(
                        battery: battery,
                        targetMode: mode
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                showBatteryModeOptions = false
                            }) {
                                Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.purple)
                            }
                        }
                    }
                    .padding()
                }
                .presentationDetents([.medium])
            }
        #endif
    }

    private func modeIcon(for mode: BatteryMode) -> Image {
        switch mode {
        case .Standard, .StandardControlled:
            Image(systemName: "battery.100percent")
        case .Eco:
            Image(systemName: "leaf")
        case .PeakShaving:
            Image(systemName: "bolt.shield")
        case .Manual:
            Image(systemName: "wrench.and.screwdriver")
        case .TariffOptimized:
            Image(systemName: "dollarsign.circle")
        }
    }
}

#Preview {
    BatteryModeButton(
        battery: .fakeBattery(),
        mode: .StandardControlled
    )

    BatteryModeButton(
        battery: .fakeBattery(),
        mode: .Eco
    )

    BatteryModeButton(
        battery: .fakeBattery(),
        mode: .Standard
    )
}
