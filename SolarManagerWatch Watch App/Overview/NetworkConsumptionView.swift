//
//  NetworkConsumptionView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//

import SwiftUI

struct NetworkConsumptionView: View {
    @Binding var currentNetworkConsumption: Int
    @Binding var currentNetworkFeedin: Int

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
            currentNetworkFeedin > 0 || currentNetworkConsumption > 0
            ? Color.orange
            : Color.secondary
    }
}

#Preview("Consume from grid") {
    NetworkConsumptionView(
        currentNetworkConsumption: Binding.constant(2300),
        currentNetworkFeedin: Binding.constant(0)
    )
}

#Preview("Feed-in to grid") {
    NetworkConsumptionView(
        currentNetworkConsumption: Binding.constant(0),
        currentNetworkFeedin: Binding.constant(3200)
    )
}

#Preview("No grid") {
    NetworkConsumptionView(
        currentNetworkConsumption: Binding.constant(0),
        currentNetworkFeedin: Binding.constant(0)
    )
}
