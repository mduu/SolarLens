import SwiftUI

struct GridBoubleView: View {
    var currentNetworkConsumption: Int
    var currentNetworkFeedin: Int
    var isFlowFromNetwork: Bool
    var isFlowToNetwork: Bool

    private let smallText: String? = "kW"
    private let color: Color = .orange

    var body: some View {
        let fromGridInKW = currentNetworkConsumption.formatWattsAsKiloWatts()
        let toGridInKW = currentNetworkFeedin.formatWattsAsKiloWatts()
        let fromToGridInKW = isFlowToNetwork ? toGridInKW : fromGridInKW

        VStack(spacing: 0) {
            CircularInstrument(
                color: getColor(
                    isFlowToNetwork: isFlowToNetwork,
                    isFlowFromNetwork: isFlowFromNetwork),
                largeText: fromToGridInKW,
                smallText: smallText
            )
            .accessibilityLabel(
                isFlowToNetwork
                    ? "Exporting \(toGridInKW) kilo-watts to grid"
                    : isFlowFromNetwork
                        ? "Consuming \(fromGridInKW) kilo-watts from grid"
                        : "No interaction with energy grid")
            .modifier(
                ConditionalFrame(
                    widthSmallWatch: 40,
                    heightSmallWatch: 40,
                    widthLargeWatch: 46,
                    heightLargeWatch: 46
                )
            )
            .padding(3)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(22)

            HStack(alignment: VerticalAlignment.bottom) {
                Image(systemName: "network")
                    .padding(.top, 3)
            }
            .padding(.top, 3)
        }
    }

    private func getColor(isFlowToNetwork: Bool, isFlowFromNetwork: Bool)
        -> Color
    {
        isFlowToNetwork || isFlowFromNetwork
            ? Color.orange
            : Color.secondary
    }
}

#Preview("Consume from grid") {
    GridBoubleView(
        currentNetworkConsumption: 2300,
        currentNetworkFeedin: 0,
        isFlowFromNetwork: true,
        isFlowToNetwork: false
    )
}

#Preview("Feed-in to grid") {
    GridBoubleView(
        currentNetworkConsumption: 0,
        currentNetworkFeedin: 3200,
        isFlowFromNetwork: false,
        isFlowToNetwork: true
    )
}

#Preview("No grid") {
    GridBoubleView(
        currentNetworkConsumption: 0,
        currentNetworkFeedin: 0,
        isFlowFromNetwork: true,
        isFlowToNetwork: false
    )
}
