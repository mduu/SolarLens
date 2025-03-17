import SwiftUI

struct BatteryBoubleView: View {
    var currentBatteryLevel: Int?
    var currentChargeRate: Int?

    var body: some View {
        HStack {
            if currentBatteryLevel != nil && currentChargeRate != nil {

                VStack(spacing: 1) {
                    Gauge(
                        value: Double(currentBatteryLevel ?? 0),
                        in: 0...100
                    ) {
                    } currentValueLabel: {
                        let formattedBatteryLevel = currentBatteryLevel.formatIntoPercentage()
                            
                        Text(formattedBatteryLevel)
                        .foregroundStyle(getColor())
                        .accessibilityLabel("Battery level is \(formattedBatteryLevel)")
                    }
                    .gaugeStyle(.accessoryCircular)
                    .tint(Gradient(colors: [.red, .green, .green, .green]))
                    .padding(4)

                    getBatterImage()
                }
            }
        }
    }
        

    private func getColor() -> Color {
        currentBatteryLevel ?? 0 < 10
            ? .red
            : currentBatteryLevel ?? 0 == 100
                ? .green
                : .primary
    }

    private func getBatterImage() -> Image {
        if currentChargeRate ?? 0 > 0 {
            return Image(systemName: "battery.100percent.bolt")
        }

        if currentBatteryLevel ?? 0 >= 95 {
            return Image(systemName: "battery.100percent")
        }

        if currentBatteryLevel ?? 0 >= 70 {
            return Image(systemName: "battery.75percent")
        }

        if currentBatteryLevel ?? 0 >= 50 {
            return Image(systemName: "battery.50percent")
        }

        if currentBatteryLevel ?? 0 >= 10 {
            return Image(systemName: "battery.25percent")
        }

        return Image(systemName: "battery.0percent")
    }
}
