//
//  SolarInfoView.swift
//  Solar Lens Watch App
//
//  Created by Marc Dürst on 13.12.2024.
//

import SwiftUI

struct SolarInfoView: View {
    @Binding var totalProducedToday: Double?
    @Binding var currentProduction: Int?

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    Image(systemName: "timer")
                        .font(.caption)

                    if totalProducedToday != nil {
                        kWValueText(
                            kwValue: Double(totalProducedToday!) / 1000
                        )
                    } else {
                        errorImage()
                    }  // :if
                }

                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 8)

                HStack {
                    Image(systemName: "bolt")
                        .font(.caption)

                    if currentProduction != nil {
                        kWValueText(
                            kwValue: Double(currentProduction!) / 1000
                        )
                    } else {
                        errorImage()
                    }  // :if

                }  // :VStack
                .padding(.all, 0)
            }  // :HStack
            .padding(.all, 0)
        }  // :Button
        .padding(.all, 0)
    }  // :body

    private func kWValueText(kwValue: Double) -> Text {
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

#Preview {
    SolarInfoView(
        totalProducedToday: .constant(2340),
        currentProduction: .constant(1420))
}
