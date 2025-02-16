import SwiftUI

struct ChargingView: View {
    var isVertical: Bool = true
    
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    
    var body: some View {
        Group {
            if isVertical {
                VStack {
                    if buildingState.overviewData
                        .isAnyCarCharing
                    {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.blue)
                            .font(
                                .system(
                                    size: 25, weight: .light
                                )
                            )
                            .symbolEffect(
                                .wiggle.byLayer,
                                options: .repeat(
                                    .periodic(delay: 0.7)))
                    } else {
                        Text("")
                            .frame(minHeight: 25)
                    }
                    
                    ChargingStationsView(
                        chargingStation: buildingState
                            .overviewData.chargingStations
                    )
                    .frame(maxWidth: 180)
                }  // :VStack
            } else {
                HStack {
                    if buildingState.overviewData
                        .isAnyCarCharing
                    {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.blue)
                            .font(
                                .system(
                                    size: 25, weight: .light
                                )
                            )
                            .symbolEffect(
                                .wiggle.byLayer,
                                options: .repeat(
                                    .periodic(delay: 0.7)))
                    } else {
                        Text("")
                            .frame(minWidth: 25)
                    }
                    
                    ChargingStationsView(
                        chargingStation: buildingState
                            .overviewData.chargingStations,
                        isVertical: isVertical
                    )
                    .frame(maxHeight: 180)
                } // :HStack
            }
        }
    }
}

#Preview("Vertical") {
    ChargingView()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()))
}

#Preview("Horizontal") {
    ChargingView(isVertical: false)
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()))
}
