//
//  ContentView.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 28.09.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = BuildingStateModel()
    
    var body: some View {
        TabView {
            OverviewView()
                .environmentObject(model)
            ProductionView()
                .environmentObject(model)
            ConsumationView()
                .environmentObject(model)
   }
        .tabViewStyle(
            .verticalPage(transitionStyle: .blur))
    }
}

#Preview {
    ContentView()
}
