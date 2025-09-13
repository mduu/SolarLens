import SwiftUI

struct SelfConsumption: View {
    var weekStatistics: Statistics
    var monthStatistics: Statistics
    var yearStatistics: Statistics
    var overallStatistics: Statistics

    var body: some View {
        VStack {
            HStack {
                Text("Self-consumption")
                    .font(.subheadline)

                Spacer()
            }
            .padding(.vertical, 4)

            ScrollView(.horizontal) {
                HStack(alignment: .center, spacing: 5) {
                    SelfConsumptionDonut(percent: Int(weekStatistics.selfConsumptionRate ?? 0), text: "7d")
                    Spacer()
                    SelfConsumptionDonut(percent: Int(monthStatistics.selfConsumptionRate ?? 0), text: "30d")
                    Spacer()
                    SelfConsumptionDonut(percent: Int(yearStatistics.selfConsumptionRate ?? 0), text: "365d")
                    Spacer()
                    SelfConsumptionDonut(percent: Int(overallStatistics.selfConsumptionRate ?? 0), text: "All")
                }
            }
        }
    }
}

#Preview {
    SelfConsumption(
        weekStatistics: Statistics(),
        monthStatistics: Statistics(),
        yearStatistics: Statistics(),
        overallStatistics: Statistics()
    )
}
