//
//  ProductionView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//


import SwiftUI

struct ProductionView: View {
    var body: some View {
        VStack {
            Image(systemName: "sun.max")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Power Production")
        }
        .padding()
    }
}