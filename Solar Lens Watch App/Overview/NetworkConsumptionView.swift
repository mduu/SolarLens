import SwiftUI

struct NetworkConsumptionView: View {
    var currentNetworkConsumption: Int
    var currentNetworkFeedin: Int
    var isFlowFromNetwork: Bool
    var isFlowToNetwork: Bool

    private let smallText: String? = "kW"
    private let color: Color = .orange

    var body: some View {
        VStack(spacing: 1) {
            CircularInstrument(
                color: getColor(
                    isFlowToNetwork: isFlowToNetwork,
                    isFlowFromNetwork: isFlowFromNetwork),
                largeText: getLargeText(
                    fromNetwork: currentNetworkConsumption,
                    toNetwork: currentNetworkFeedin),
                smallText: smallText
            )

            Image(systemName: "network")
                .padding(.top, 3)
        }
    }

    private func getLargeText(fromNetwork: Int, toNetwork: Int) -> String {
        String(
            format: "%.1f",
            Double(toNetwork > 0 ? toNetwork : fromNetwork) / 1000)
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
    NetworkConsumptionView(
        currentNetworkConsumption: 2300,
        currentNetworkFeedin: 0,
        isFlowFromNetwork: true,
        isFlowToNetwork: false
    )
}

#Preview("Feed-in to grid") {
    NetworkConsumptionView(
        currentNetworkConsumption: 0,
        currentNetworkFeedin: 3200,
        isFlowFromNetwork: false,
        isFlowToNetwork: true
    )
}

#Preview("No grid") {
    NetworkConsumptionView(
        currentNetworkConsumption: 0,
        currentNetworkFeedin: 0,
        isFlowFromNetwork: true,
        isFlowToNetwork: false
    )
}
