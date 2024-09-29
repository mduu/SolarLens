//
//  ContentView.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 28.09.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            OverviewView()
            ProductionView()
            ConsumationView()
        }
        .tabViewStyle(
            .verticalPage(transitionStyle: .blur))
    }
}

#Preview {
    ContentView()
}
