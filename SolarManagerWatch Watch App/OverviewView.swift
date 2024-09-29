//
//  OverviewView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//


import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var model: BuildingStateModel
    
    var body: some View {
        VStack {
            Image(systemName: "house")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("House Overview")
            Text("Solar Power: \(model.currentSolarProduction, specifier:"%.2f")")
        }
        .padding()
    }
}

#Preview {
    OverviewView()
}
