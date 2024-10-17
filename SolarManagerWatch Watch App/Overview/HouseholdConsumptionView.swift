//
//  HouseholdConsumptionView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//

import SwiftUI

struct HouseholdConsumptionView: View {
    @Binding var currentOverallConsumption: Int

    @State var circleColor: Color = .green
    @State var circleLargeText: String = "-"
    @State var circleSmallText: String? = "kW"

    var body: some View {
        VStack(spacing: 0) {
            CircularInstrument(
                color: $circleColor,
                largeText: $circleLargeText,
                smallText: $circleSmallText
            )
            .onChange(of: currentOverallConsumption, initial: true) { newValue, transition in
                circleLargeText = String(
                    format: "%.1f",
                    Double(newValue) / 1000
                )
            }

            Image(systemName: "house")
                .padding(.top, 3)
        }
    }
}

#Preview {
    HouseholdConsumptionView(
        currentOverallConsumption: Binding.constant(1230)
    )
}
