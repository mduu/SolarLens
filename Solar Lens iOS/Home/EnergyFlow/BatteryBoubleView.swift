import SwiftUI

struct BatteryBoubleView: View {
    var currentBatteryLevel: Int?
    var currentChargeRate: Int?

    @State var showBatterySheet: Bool = false

    var body: some View {
        if currentBatteryLevel != nil {
            let level = currentBatteryLevel ?? 0

            EnergyCard(
                icon: batteryIconName,
                iconColor: batteryColor(level: level),
                label: "Battery",
                value: "\(level)%",
                showChevron: true,
                customDetail: {
                    BatteryBar(level: level, color: batteryColor(level: level))
                }
            )
            .onTapGesture { showBatterySheet = true }
            .sheet(isPresented: $showBatterySheet) {
                NavigationView {
                    BatterySheet()
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func batteryColor(level: Int) -> Color {
        if level > 10 { return .green }
        if level > 6 { return .orange }
        return .red
    }

    private var batteryIconName: String {
        if currentChargeRate ?? 0 > 0 {
            return "battery.100percent.bolt"
        }
        let level = currentBatteryLevel ?? 0
        if level >= 95 { return "battery.100percent" }
        if level >= 70 { return "battery.75percent" }
        if level >= 50 { return "battery.50percent" }
        if level >= 10 { return "battery.25percent" }
        return "battery.0percent"
    }
}

/// A compact horizontal bar showing battery fill level.
private struct BatteryBar: View {
    let level: Int
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 3)
                    .fill(color.opacity(0.15))

                // Fill
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.6), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(min(level, 100)) / 100)
            }
        }
        .frame(height: 6)
        .frame(maxWidth: 100)
    }
}

#Preview("Low") {
    BatteryBoubleView(
        currentBatteryLevel: 8,
        currentChargeRate: 0
    )
    .frame(width: 170)
    .padding()
}

#Preview("Medium") {
    BatteryBoubleView(
        currentBatteryLevel: 45,
        currentChargeRate: 1234
    )
    .frame(width: 170)
    .padding()
}

#Preview("High") {
    BatteryBoubleView(
        currentBatteryLevel: 87,
        currentChargeRate: 0
    )
    .frame(width: 170)
    .padding()
}
