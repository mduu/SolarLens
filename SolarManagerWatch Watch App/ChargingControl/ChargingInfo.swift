//
//  ChargingInfo.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 08.12.2024.
//

import SwiftUI

struct ChargingInfo: View {
    @Binding var totalChargedToday: Double?
    @Binding var currentChargingPower: Int?

    var body: some View {
        VStack {
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "timer")
                        .font(.caption)

                    if totalChargedToday != nil {
                        kWValueText(
                            kwValue: Double(totalChargedToday!) / 1000,
                            unit: "kWh"
                        )
                    } else {
                        errorImage()
                    }  // :if
                }
                .padding(.trailing, 4)

                HStack {
                    Image(systemName: "bolt")
                        .font(.caption)

                    if currentChargingPower != nil {
                        kWValueText(
                            kwValue: Double(currentChargingPower!) / 1000,
                            unit: "kW"
                        )
                    } else {
                        errorImage()
                    }  // :if

                }  // :VStack
            }  // :HStack
        }  // :VStack
    }  // :body

    private func kWValueText(kwValue: Double, unit: String) -> Text {
        return Text(
            String(format: "%.1f", kwValue)
        )
        .foregroundColor(.accent)
    }

    private func errorImage() -> some View {
        return Image(systemName: "exclamationmark.icloud")
            .foregroundColor(Color.red)
            .symbolEffect(
                .pulse.wholeSymbol,
                options: .repeat(.continuous))
    }
}

#Preview("Normal") {
    ChargingInfo(
        totalChargedToday: .constant(23456.56),
        currentChargingPower: .constant(5678)
    )
}

#Preview("Zero") {
    ChargingInfo(
        totalChargedToday: .constant(0),
        currentChargingPower: .constant(0)
    )
}

#Preview("No data") {
    ChargingInfo(
        totalChargedToday: .constant(nil),
        currentChargingPower: .constant(nil)
    )
}
