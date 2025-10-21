import SwiftUI

struct TodayWidget: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState

    @State private var todayConsumption: MainData? = nil
    @State private var initialLoadTimer: Timer?
    @State private var refreshTimer: Timer?

    var body: some View {
        WidgetBase(title: "Today") {

            if let todayConsumption {

                OverviewChart(
                    consumption: todayConsumption,
                    showBatteryCharge: false,
                    showBatteryDischange: false,
                    useAlternativeColors: true
                )
                .frame(maxHeight: 400)

            } else {
                ProgressView()
            }

            Divider()
                .padding(.top)

            TodayConsumptionView(
                consumptionTodayInWatts: buildings.overviewData.todayConsumption,
                todayGridImported: buildings.overviewData.todayGridImported
            )
            .padding(.top)

        }
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
        let newConsumptionData = await buildings.fetchConsumptionForToday()

        guard let newConsumptionData else {
            return
        }

        self.todayConsumption = newConsumptionData
    }

}

#Preview {
    VStack(alignment: .leading) {

        HStack(alignment: .top) {
            TodayWidget()

            Spacer()
        }
        .frame(width: 550, height: 400)

        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.blue.opacity(0.4))
    .environment(CurrentBuildingState.fake())
}
