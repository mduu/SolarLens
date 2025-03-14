import SwiftUI

struct ConsumptionPageView: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    @State private var refreshTimer: Timer?

    var body: some View {
        ZStack {

            LinearGradient(
                gradient: Gradient(colors: [
                    .cyan.opacity(0.5), .cyan.opacity(0.2),
                ]), startPoint: .top, endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {

                VStack {

                    ConsumptionTodayInfoView(
                        totalConsumpedToday: buildingState.overviewData
                            .todayConsumption,
                        currentConsumption: buildingState.overviewData
                            .currentOverallConsumption)

                    Divider()

                    DeviceListView(
                        devices: buildingState.overviewData.devices
                    ) { deviceId, newPriority in
                        print(
                            "Setting prio of device \(deviceId) to \(newPriority)"
                        )

                        Task {
                            await buildingState.setSensorPriority(
                                sensorId: deviceId, newPriority: newPriority)
                        }

                        print(
                            "Prio of device \(deviceId) set to \(newPriority).")
                    }

                }  // :VStack
                .padding(.leading, 2)
                .padding(.trailing, 10)

            }  // :ScrollView

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
    }
}

#Preview {
    ConsumptionPageView()
        .environment(
            CurrentBuildingState.fake()
        )
}
