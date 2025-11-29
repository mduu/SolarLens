import SwiftUI

struct CurrentWeekWdiget: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState
    @State private var refreshTimer: Timer?
    @State private var weekData: [DayStatistic]?
    @State private var lastSuccessfulFetch: Date?

    var body: some View {
        WidgetBase(title: "Week") {
            VStack {
                WeekOverviewChartView(weekData: weekData)

                Spacer()
            }
        }
        .frame(maxHeight: 500)
        .onAppear {

            Task {
                await fetch()
            }

            if refreshTimer == nil {
                refreshTimer = Timer.scheduledTimer(
                    withTimeInterval: 15,
                    repeats: true
                ) {
                    _ in
                    if lastSuccessfulFetch.isOlderThen(secondsSinceNow: 120) {
                        Task {
                            await fetch()
                        }
                    }
                }

            }

        }
        .onDisappear {
            if let refreshTimer {
                refreshTimer.invalidate()
                self.refreshTimer = nil
            }
        }

    }

    private func fetch() async {
        let newConsumptionData = await buildings.fetchStatisticsForPast7Days()

        guard let newConsumptionData else {
            return
        }

        weekData = newConsumptionData
    }
}

#Preview {
    CurrentWeekWdiget()
        .environment(CurrentBuildingState.fake())
}
