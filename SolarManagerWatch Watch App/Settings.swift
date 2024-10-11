//
//  Settings.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 11.10.2024.
//

import SwiftUI

struct Settings: View {
    @EnvironmentObject var model: BuildingStateViewModel
    
    var body: some View {
        VStack(alignment: .leading)
        {
            Text("Settings")
                .font(.largeTitle)
                    .foregroundColor(.blue)

            Button("Log out")
            {
                model.logout()
            }
        
            Spacer()
        }
        
        Spacer()
    }
}

#Preview {
    Settings()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            ))
}
