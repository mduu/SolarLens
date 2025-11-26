import SwiftUI

struct SolarForecastWidget: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState

    @State private var initialLoadTimer: Timer?
    @State private var refreshTimer: Timer?
    @State private var solarDetails: SolarDetailsData?

    var body: some View {
        WidgetBase(title: "Forecast") {
            ThreeDaysForecastView(solarDetails: solarDetails)
            Spacer()
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
        await buildings.fetchSolarDetails()

        guard let solarDetailsData = buildings.solarDetailsData else {
            return
        }

        self.solarDetails = solarDetailsData
    }
}

#Preview {
    SolarForecastWidget()
        .environment(CurrentBuildingState.fake())
}
