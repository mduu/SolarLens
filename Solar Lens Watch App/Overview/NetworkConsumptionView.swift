import SwiftUI

struct NetworkConsumptionView: View {
    @Binding var currentNetworkConsumption: Int
    @Binding var currentNetworkFeedin: Int
    var isFlowFromNetwork: Bool
    var isFlowToNetwork: Bool

    @State var largeText: String = "-"
    @State var smallText: String? = "kW"
    @State var color: Color = .orange

    var body: some View {
        VStack(spacing: 1) {
            CircularInstrument(
                color: $color,
                largeText: $largeText,
                smallText: $smallText
            )
            .onChange(of: currentNetworkConsumption, initial: true) {
                oldValue, newValue in
                largeText = getLargeText(
                    fromNetwork: newValue, toNetwork: currentNetworkFeedin)
                updateColor()
            }
            .onChange(of: currentNetworkFeedin, initial: true) {
                oldValue, newValue in
                largeText = getLargeText(
                    fromNetwork: currentNetworkConsumption, toNetwork: newValue)
                updateColor()
            }

            Image(systemName: "network")
                .padding(.top, 3)
        }
    }

    private func getLargeText(fromNetwork: Int, toNetwork: Int) -> String {
        return String(
            format: "%.1f",
            Double(toNetwork > 0 ? toNetwork : fromNetwork) / 1000)
    }

    private func updateColor() {
        color =
        isFlowToNetwork || isFlowFromNetwork
            ? Color.orange
            : Color.secondary
    }
}

#Preview("Consume from grid") {
    NetworkConsumptionView(
        currentNetworkConsumption: Binding.constant(2300),
        currentNetworkFeedin: Binding.constant(0),
        isFlowFromNetwork: true,
        isFlowToNetwork: false
    )
}

#Preview("Feed-in to grid") {
    NetworkConsumptionView(
        currentNetworkConsumption: Binding.constant(0),
        currentNetworkFeedin: Binding.constant(3200),
        isFlowFromNetwork: false,
        isFlowToNetwork: true
    )
}

#Preview("No grid") {
    NetworkConsumptionView(
        currentNetworkConsumption: Binding.constant(0),
        currentNetworkFeedin: Binding.constant(0),
        isFlowFromNetwork: true,
        isFlowToNetwork: false
    )
}
