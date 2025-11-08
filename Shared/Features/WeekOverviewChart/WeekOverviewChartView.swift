import SwiftUI
import Charts

struct WeekOverviewChartView: View {
    var weekData: MainData?

    var body: some View {
        Chart {

        }
    }

    private func getSumPerDay() -> [DaySum]
    {
        
        return []
    }

    private struct DaySum {
        var date: Date
        var sumProduction: Double
        var sumConsumption: Double
        var sumGridImport: Double
        var sumGridExport: Double
    }
}


#Preview {
    WeekOverviewChartView()
}
