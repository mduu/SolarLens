import SwiftUI

struct FooterView: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    
    var body: some View {
        VStack {
            SiriDiscoveryView()
                .padding(.vertical, 0)
            UpdateTimeStampView(
                isStale: buildingState.overviewData.isStaleData,
                updateTimeStamp: buildingState.overviewData
                    .lastSuccessServerFetch,
                isLoading: buildingState.isLoading,
                onRefresh: nil
            )
            .padding(.bottom)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        
        FooterView()
            .environment(
                CurrentBuildingState.fake(
                    overviewData: OverviewData.fake()))
    }
    .ignoresSafeArea()
}
