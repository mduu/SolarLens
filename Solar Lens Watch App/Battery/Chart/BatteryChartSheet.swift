import SwiftUI

struct BatteryChartSheet: View {
    @State var viewModel = BatteryChartViewModel()
    @State private var refreshTimer: Timer?

    var body: some View {
        ZStack {
            VStack {
                if viewModel.error == nil && viewModel.errorMessage == nil {
                    if let mainData = viewModel.mainData,
                       let batteryHistory = viewModel.batteryHistory,
                       !batteryHistory.isEmpty
                    {
                        BatteryChart(
                            mainData: mainData,
                            batteryHistory: batteryHistory
                        )

                        let totalCharged = mainData.data.reduce(0.0) { $0 + $1.batteryChargedWh }
                        let totalDischarged = mainData.data.reduce(0.0) { $0 + $1.batteryDischargedWh }

                        HStack(spacing: 12) {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.purple)
                                Text(totalCharged.formatWattHoursAsKiloWattsHours(widthUnit: true))
                                    .font(.system(size: 10))
                            }
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.indigo)
                                Text(totalDischarged.formatWattHoursAsKiloWattsHours(widthUnit: true))
                                    .font(.system(size: 10))
                            }
                        }
                        .padding(.top, 2)
                    } else {
                        Spacer()
                        Text("No data")
                            .font(.footnote)
                        Spacer()
                    }
                }
            }
            .padding(8)
            .ignoresSafeArea(edges: .horizontal.union(.bottom))

            if viewModel.isLoading {
                ProgressView()
                    .tint(.accent)
                    .padding()
                    .foregroundStyle(.accent)
                    .background(Color.black.opacity(0.7))
            }
        }
        .onAppear {
            Task {
                await viewModel.fetch()

                if refreshTimer == nil {
                    refreshTimer = Timer.scheduledTimer(
                        withTimeInterval: 300, repeats: true
                    ) { _ in
                        Task {
                            await viewModel.fetch()
                        }
                    }
                }
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }
}

#Preview {
    BatteryChartSheet(
        viewModel: BatteryChartViewModel.previewFake()
    )
}
