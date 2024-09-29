//
//  ConsumationView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//


import SwiftUI

struct ConsumationView: View {
    var body: some View {
        VStack {
            Image(systemName: "poweroutlet.type.h")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Power-Consumption")
        }
        .padding()
    }
}