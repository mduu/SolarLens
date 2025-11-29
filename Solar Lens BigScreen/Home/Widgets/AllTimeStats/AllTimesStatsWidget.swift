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
                    Text("Consumption")
                        .foregroundColor(.blue)

                    Spacer()

                    let totalConsumption =
                        alltimesStats?.consumption != nil
                        ? alltimesStats!.consumption!.formatWattHoursAsMegaWattsHours(widthUnit: true)
                        : "-"

                    Text(totalConsumption)
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }

                HStack {
                    Text("Production")
                        .foregroundColor(.yellow)

                    Spacer()

                    let totalProduction =
                        alltimesStats?.production != nil
                        ? alltimesStats!.production!.formatWattHoursAsMegaWattsHours(widthUnit: true)
                        : "-"

                    Text(totalProduction)
                        .font(.system(size: 32))
                        .foregroundColor(.yellow)
                }

                HStack {
                    Text("Self consumption")
                        .foregroundColor(.indigo)

                    Spacer()

                    let totalSelfConsumption =
                        alltimesStats?.selfConsumption != nil
                        ? alltimesStats!.selfConsumption!.formatWattHoursAsMegaWattsHours(widthUnit: true)
                        : "-"

                    Text(totalSelfConsumption)
                        .font(.system(size: 32))
                        .foregroundColor(.indigo)
                }

                HStack {
                    Spacer()

                    let totalSelfConsumptionRate =
                        alltimesStats?.selfConsumptionRate != nil
                        ? alltimesStats!.selfConsumptionRate!.formatIntoPercentage()
                        : "-"

                    Text(totalSelfConsumptionRate)
                        .font(.system(size: 32))
                        .foregroundColor(.indigo)
                }

                HStack {

                    Text("Autarky")
                        .foregroundColor(.purple)

                    Spacer()

                    let totalAutarky =
                        alltimesStats?.autarchyDegree != nil
                        ? alltimesStats!.autarchyDegree!.formatIntoPercentage()
                        : "-"

                    Text(totalAutarky)
                        .font(.system(size: 32))
                        .foregroundColor(.purple)
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
        .frame(width: 600)

        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.blue.gradient)
}
