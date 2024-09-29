//
//  OverviewView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//


import SwiftUI

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

#Preview {
    OverviewView()
}
