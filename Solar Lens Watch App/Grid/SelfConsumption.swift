import SwiftUI

struct SelfConsumption: View {
    var weekStatistics: Statistics
    var monthStatistics: Statistics
    var yearStatistics: Statistics
    var overallStatistics: Statistics
    var isSmall: Bool

    var body: some View {
        VStack {
            HStack {
                Text("Self consumption")
                    .font(.subheadline)

                Spacer()
            }
            .padding(.bottom, 4)

            ScrollView(.horizontal) {
                HStack(alignment: .center, spacing: 5) {
                    SelfConsumptionDonut(
                        percent: Int(weekStatistics.selfConsumptionRate ?? 0),
                        text: "7d",
                        isSmall: isSmall
                    )
                    Spacer()
                    SelfConsumptionDonut(
                        percent: Int(monthStatistics.selfConsumptionRate ?? 0),
                        text: "30d",
                        isSmall: isSmall
                    )
                    Spacer()
                    SelfConsumptionDonut(
                        percent: Int(yearStatistics.selfConsumptionRate ?? 0),
                        text: "365d",
                        isSmall: isSmall
                    )
                    Spacer()
                    SelfConsumptionDonut(
                        percent: Int(overallStatistics.selfConsumptionRate ?? 0),
                        text: "All",
                        isSmall: isSmall
                    )
                }
            }
        }
    }
}

#Preview("Large") {
    SelfConsumption(
        weekStatistics: Statistics(),
        monthStatistics: Statistics(),
        yearStatistics: Statistics(),
        overallStatistics: Statistics(),
        isSmall: false
    )
}

#Preview("Small") {
    VStack {

        Text("Large")
        SelfConsumption(
            weekStatistics: Statistics(),
            monthStatistics: Statistics(),
            yearStatistics: Statistics(),
            overallStatistics: Statistics(),
            isSmall: false
        )

        Divider()

        Text("Small")
        SelfConsumption(
            weekStatistics: Statistics(),
            monthStatistics: Statistics(),
            yearStatistics: Statistics(),
            overallStatistics: Statistics(),
            isSmall: true
        )

    }
}
