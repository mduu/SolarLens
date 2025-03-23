import SwiftUI

struct ChargingInfo: View {
    @Binding var totalChargedToday: Double?
    @Binding var currentChargingPower: Int?

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    Image(systemName: "calendar")
                        .font(.caption)

                    if totalChargedToday != nil {
                        kWValueText(
                            kwValue: Double(totalChargedToday!) / 1000
                        )
                    } else {
                        errorImage()
                    }  // :if
                }

                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 8)

                HStack {
                    Image(systemName: "bolt")
                        .font(.caption)

                    if currentChargingPower != nil {
                        kWValueText(
                            kwValue: Double(currentChargingPower!) / 1000
                        )
                    } else {
                        errorImage()
                    }  // :if

                }  // :VStack
                .padding(.all, 0)
            }  // :HStack
            .padding(.all, 0)
        }  // :Button
        .padding(.all, 0)
    }  // :body

    private func kWValueText(kwValue: Double) -> Text {
        return Text(
            String(format: "%.1f", kwValue)
        )
        .foregroundColor(.accent)
    }

    private func errorImage() -> some View {
        return Image(systemName: "exclamationmark.icloud")
            .foregroundColor(Color.red)
            .symbolEffect(
                .pulse.wholeSymbol,
                options: .repeat(.continuous))
    }
}

#Preview("Normal") {
    ChargingInfo(
        totalChargedToday: .constant(23456.56),
        currentChargingPower: .constant(5678)
    )
}

#Preview("Zero") {
    ChargingInfo(
        totalChargedToday: .constant(0),
        currentChargingPower: .constant(0)
    )
}

#Preview("No data") {
    ChargingInfo(
        totalChargedToday: .constant(nil),
        currentChargingPower: .constant(nil)
    )
}
