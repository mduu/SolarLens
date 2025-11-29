import SwiftUI

struct AllTimesStatsWidget: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState
    @State private var refreshTimer: Timer?
    @State private var alltimesStats: Statistics?
    @State private var lastSuccessfulUpdate: Date?

    let refreshIntervalInSeconds = 4 * 60 * 60  // 4h

    var body: some View {
        WidgetBase(title: "All times") {
            VStack {
                HStack {
                    Label("Consumption", systemImage: "sun.max")

                    Spacer()

                    let totalConsumption =
                        alltimesStats?.consumption != nil
                        ? alltimesStats!.consumption!.formatWattHoursAsMegaWattsHours(widthUnit: true)
                        : "-"

                    Text(totalConsumption)
                        .font(.system(size: 32))
                }

                HStack {
                    Label("Production", systemImage: "powerplug")

                    Spacer()

                    let totalProduction =
                        alltimesStats?.production != nil
                        ? alltimesStats!.production!.formatWattHoursAsMegaWattsHours(widthUnit: true)
                        : "-"

                    Text(totalProduction)
                        .font(.system(size: 32))
                }

                HStack {
                    let totalSelfConsumptionRate = alltimesStats?.selfConsumptionRate ?? 0
                    SelfConsumptionDonut(selfConsumptionPercent: totalSelfConsumptionRate)

                    let totalAutarky = alltimesStats?.autarchyDegree ?? 0
                    AutarkyDonut(autarkyPercent: totalAutarky)
                }

                Spacer()
            }
            .padding(.top)
        }
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
                    if lastSuccessfulUpdate.isOlderThen(secondsSinceNow: refreshIntervalInSeconds) {
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
        let newAlltimesStats = await buildings.fetchAllimeStatistics()

        guard let newAlltimesStats else {
            return
        }

        alltimesStats = newAlltimesStats
    }
}

#Preview {
    HStack {
        VStack {
            AllTimesStatsWidget()
                .environment(CurrentBuildingState.fake())

            Spacer()
        }
        .frame(width: 600, height: 600)

        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.blue.gradient)
}
