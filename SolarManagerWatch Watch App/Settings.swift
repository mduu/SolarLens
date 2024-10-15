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
        VStack(alignment: .center) {
            Text("Settings")
                .font(.largeTitle)
                .foregroundColor(.blue)
                .padding(.bottom, 16)

            Button("Log out") {
                model.logout()
            }
            
            Spacer()

            HStack {
                Text(
                    "Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
                )
                Text(
                    "Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")"
                )
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.footnote)
            .foregroundColor(.gray)
            .padding(.top, 20)
        }

    }
}

#Preview {
    Settings()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            ))
}
