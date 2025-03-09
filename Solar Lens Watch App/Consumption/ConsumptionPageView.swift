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
                Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            } // :VStack
        } // :ZStack
    }
}

#Preview {
    ConsumptionPageView()
        .environment(
            CurrentBuildingState.fake()
        )
}
