import SwiftUI

struct GridScreen: View {
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState
    @State var isLoading = false
    @State var energyOverview: EnergyOverview? = nil

    var body: some View {
        ZStack {

            LinearGradient(
                gradient: Gradient(colors: [
                    .indigo.opacity(0.4), .indigo.opacity(0.1),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in

                ScrollView {

                    VStack(alignment: .leading) {

                        EfficiencyInfoView(
                            todaySelfConsumptionRate: model
                                .overviewData
                                .todaySelfConsumptionRate,
                            todayAutarchyDegree: model
                                .overviewData
                                .todayAutarchyDegree,
                            showLegend: true,
                            showTitle: false,
                            legendAtBottom: false
                        )
                        .frame(minWidth: 47, maxHeight: 47)

                        if energyOverview?.loaded ?? false {
                            VStack {
                                AutarkyDetails(energyOverview: energyOverview)
                            }
                            .padding(.top, 12)
                        }
                    }  // :VStack

                }  // :ScrollView

            }  // :GeometryReader
            .padding(.horizontal)

            if isLoading {
                ProgressView()
                    .tint(.orange)
                    .padding()
                    .foregroundStyle(.orange)
                    .background(Color.black.opacity(0.7))
            }

        }  // :ZStack
        .onAppear {
            isLoading = true

            Task {
                energyOverview = try await SolarManager.instance().fetchEnergyOverview()
            }

            isLoading = false
        }
    }
}

#Preview {
    let energyOverview: EnergyOverview = EnergyOverview(
        loaded: true,
        autarchy: EnergyAutarchy(
            last24hr: 99,
            lastMonth: 70,
            lastYear: 50,
            overall: 30
        )
    )

    GridScreen(
        energyOverview: energyOverview
    )
    .environment(CurrentBuildingState.fake())
}
