import SwiftUI

struct ConsumptionTodayInfoView: View {
    var totalConsumpedToday: Double?
    var currentConsumption: Int?

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    Image(systemName: "calendar")
                        .font(.caption)

                    if totalConsumpedToday != nil {
                        kWValueText(
                            kwValue: Double(totalConsumpedToday!) / 1000
                        )
                    }  // :if
                }

                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 8)

                HStack {
                    Image(systemName: "bolt")
                        .font(.caption)

                    if currentConsumption != nil {
                        kWValueText(
                            kwValue: Double(currentConsumption!) / 1000
                        )
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
        .foregroundColor(.cyan)
    }

    private func progressSymbol() -> some View {
        return Image(systemName: "progress.indicator")
            .symbolEffect(.rotate.byLayer, options: .repeat(.continuous))
    }
}

#Preview {
    ConsumptionTodayInfoView(
        totalConsumpedToday: 2340,
        currentConsumption: 940)
}
