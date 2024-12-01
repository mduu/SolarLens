//
//  HouseholdConsumptionView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//

import SwiftUI

struct HouseholdConsumptionView: View {
    @Binding var currentOverallConsumption: Int
    @Binding var isAnyCarCharging: Bool

    @State var circleColor: Color = .teal
    @State var circleLargeText: String = "-"
    @State var circleSmallText: String? = "kW"

    var body: some View {
        VStack(spacing: 0) {
            CircularInstrument(
                color: $circleColor,
                largeText: $circleLargeText,
                smallText: $circleSmallText
            )
            .onChange(of: currentOverallConsumption, initial: true) {
                oldValue, newValue in
                circleLargeText = String(
                    format: "%.1f",
                    Double(newValue) / 1000
                )
            }

            HStack(alignment: VerticalAlignment.bottom) {
                Image(systemName: "house")
                if isAnyCarCharging {
                    Image(systemName: "car.side")
                        .symbolEffect(
                            .pulse.wholeSymbol, options: .repeat(.continuous))
                }
            }
                .padding(.top, 3)

        }
    }
}

#Preview("No charing") {
    HouseholdConsumptionView(
        currentOverallConsumption: Binding.constant(1230),
        isAnyCarCharging: Binding.constant(false)
    )
}

#Preview("Charing") {
    HouseholdConsumptionView(
        currentOverallConsumption: Binding.constant(1230),
        isAnyCarCharging: Binding.constant(true)
    )
}
