import SwiftUI

struct ConsumptionScreen: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    @State private var showDetail: Bool = false

    var body: some View {
        ZStack {

            LinearGradient(
                gradient: Gradient(colors: [
                    .cyan.opacity(0.5), .cyan.opacity(0.2),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {

                VStack {

                    HStack {
                        ConsumptionTodayInfoView(
                            totalConsumpedToday: buildingState.overviewData
                                .todayConsumption,
                            currentConsumption: buildingState.overviewData
                                .currentOverallConsumption
                        )
                        .frame(maxWidth: .infinity, alignment: .center)

                        RoundChartButton {
                            showDetail = true
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)

                    Divider()

                    DeviceList(
                        devices: buildingState.overviewData.devices
                    ) { deviceId, newPriority in
                        print(
                            "Setting prio of device \(deviceId) to \(newPriority)"
                        )

                        Task {
                            await buildingState.setSensorPriority(
                                sensorId: deviceId,
                                newPriority: newPriority
                            )
                        }

                        print(
                            "Prio of device \(deviceId) set to \(newPriority)."
                        )
                    }

                    UpdateTimeStampView(
                        isStale: buildingState.overviewData.isStaleData,
                        updateTimeStamp: buildingState.overviewData.lastUpdated,
                        isLoading: buildingState.isLoading,
                        onRefresh: nil
                    )
                    .padding(.top, 4)

                }  // :VStack
                .padding(.leading, 2)
                .padding(.trailing, 10)

            }  // :ScrollView
            .padding(.bottom, -20)

            if buildingState.isChangingSensorPriority {
                HStack {
                    ProgressView()
                        .foregroundColor(.cyan)
                }  // :HStack
                .background(Color.black.opacity(0.8))
            }
        }  // :ZStack
        .onAppear {
            Task {
                await buildingState.fetchServerData()
            }
        }
        .sheet(isPresented: $showDetail) {
            ConsumptionDetailSheet(
                totalCurrentConsumptionInWatt: buildingState.overviewData
                    .currentOverallConsumption,
                devices: buildingState.overviewData.devices
            )
            .navigationTitle {
                Text("Consumption")
                    .foregroundColor(.cyan)
                    .font(.headline)
            }
        }
    }
}

#Preview {
    ConsumptionScreen()
        .environment(
            CurrentBuildingState.fake()
        )
}
