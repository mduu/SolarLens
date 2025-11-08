import SwiftUI

struct CurrentWeekWdiget: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState
    @State private var refreshTimer: Timer?
    @State private var weekData: [DayStatistic]?

    var body: some View {
        WidgetBase(title: "Week") {
            VStack {
                Spacer()
            }
        }
        .frame(maxHeight: 600)
        .onAppear {

            Task {
                await fetch()
            }

            if refreshTimer == nil {
                refreshTimer = Timer.scheduledTimer(
                    withTimeInterval: 120,
                    repeats: true
                ) {
                    _ in
                    Task {
                        await fetch()
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
