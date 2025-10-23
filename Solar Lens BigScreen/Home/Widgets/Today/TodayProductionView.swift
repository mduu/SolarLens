import SwiftUI

struct TodayProductionView: View {
    var productionTodayInWatts: Double?
    var todayGridExported: Int?

    var body: some View {
        let exportedToGrid: Double? = todayGridExported != nil ? Double(todayGridExported!) : 0.0

        VStack {
            Text("Production")

            SelfConsumptionSourcePieChart(
                productionTodayInWatts: productionTodayInWatts,
                todayGridExported: exportedToGrid,
            )

            Spacer()
        }
    }
}

#Preview {
    VStack {

        HStack {
            TodayProductionView(
                productionTodayInWatts: 6000,
                todayGridExported: 1200
            )
            .frame(maxWidth: 600)

            Spacer()
        }

        Spacer()
    }
}
