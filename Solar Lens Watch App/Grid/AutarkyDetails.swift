import SwiftUI

struct AutarkyDetails: View {
    var weekStatistics: Statistics
    var monthStatistics: Statistics
    var yearStatistics: Statistics
    var overallStatistics: Statistics
    var isSmall: Bool

    var body: some View {
        VStack {
            HStack {
                Text("Autarky")
                    .font(.subheadline)

                Spacer()
            }
            .padding(.vertical, 4)

            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .center, spacing: 5) {
                    AutarkyDonut(
                        percent: Int(weekStatistics.autarchyDegree ?? 0),
                        text: "7d",
                        isSmall: isSmall)
                    Spacer()
                    AutarkyDonut(
                        percent: Int(monthStatistics.autarchyDegree ?? 0),
                        text: "30d",
                        isSmall: isSmall)
                    Spacer()
                    AutarkyDonut(
                        percent: Int(yearStatistics.autarchyDegree ?? 0),
                        text: "365d",
                        isSmall: isSmall)
                    Spacer()
                    AutarkyDonut(
                        percent: Int(overallStatistics.autarchyDegree ?? 0),
                        text: "All",
                        isSmall: isSmall)
                }
            }
        }
    }
}

#Preview {
    VStack {
        Text("Large")
        AutarkyDetails(
            weekStatistics: Statistics(),
            monthStatistics: Statistics(),
            yearStatistics: Statistics(),
            overallStatistics: Statistics(),
            isSmall: false
        )

        Divider()

        Text("Small")
        AutarkyDetails(
            weekStatistics: Statistics(),
            monthStatistics: Statistics(),
            yearStatistics: Statistics(),
            overallStatistics: Statistics(),
            isSmall: true
        )
    }
}
