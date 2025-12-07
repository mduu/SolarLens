import Charts
import SwiftUI

struct TodayConsumptionView: View {
    var consumptionTodayInWatts: Double?
    var todayGridImported: Int?

    var body: some View {
        let importFromGrid: Double? = todayGridImported != nil ? Double(todayGridImported!) : 0.0

        VStack {
            Text("Consumption")

            ConsumptionSourcePieChart(
                consumptionTodayInWatts: consumptionTodayInWatts,
                todayGridImported: importFromGrid
            )

            Spacer()
        }
    }
}

#Preview {
    VStack {

        HStack {
            TodayConsumptionView(
                consumptionTodayInWatts: 6000, todayGridImported: 1200
            )
                .frame(maxWidth: 600)

            Spacer()
        }

        Spacer()
    }
}
