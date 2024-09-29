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

struct OverviewView: View {
    var body: some View {
        VStack {
            Image(systemName: "house")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("House Overview")
        }
        .padding()
    }
}

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
