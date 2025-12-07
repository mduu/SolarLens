import SwiftUI

struct CurrentBatteryView: View {
    var currentBatteryLevel: Int?
    var currentChargeRate: Int?

    var body: some View {
        VStack {

            getBatterImage()
                .font(.system(size: 50))

            Text(
                currentBatteryLevel.formatIntoPercentage()
            )

        }
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

#Preview {
    CurrentBatteryView(
        currentBatteryLevel: 30,
        currentChargeRate: 1234
    )
}
