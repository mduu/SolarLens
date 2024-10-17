//
//  NetworkConsumptionView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//


import SwiftUI

struct NetworkConsumptionView: View {
    @Binding var currentNetworkConsumption: Int
    
    @State var circleColor: Color = .orange
    @State var largeText: String = "-"
    @State var smallText: String? = "kW"

    var body: some View {
        VStack(spacing: 1) {
            CircularInstrument(
                color: $circleColor,
                largeText: $largeText,
                smallText: $smallText)
            .onChange(of: currentNetworkConsumption, initial: true) { oldValue, newValue in
                largeText = String(
                    format: "%.1f",
                    Double(newValue) / 1000)
            }
           
            Image(systemName: "network")
                .padding(.top, 3)
   }
    }
}
