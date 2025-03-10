import SwiftUI

struct ConsumptionPageView: View {
    @Environment(CurrentBuildingState.self) var buildingModel: CurrentBuildingState
    @State private var refreshTimer: Timer?

    var body: some View {
        ZStack {
            
            LinearGradient(
                gradient: Gradient(colors: [
                    .cyan.opacity(0.5), .cyan.opacity(0.2),
                ]), startPoint: .top, endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                DeviceListView(devices: buildingModel.overviewData.devices)
            } // :VStack
            .padding(.leading, 2)
            .padding(.trailing, 10)
        } // :ZStack
    }
}

#Preview {
    ConsumptionPageView()
        .environment(
            CurrentBuildingState.fake()
        )
}
