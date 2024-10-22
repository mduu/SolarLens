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
        ScrollView {
            VStack(alignment: .center) {
                Text("Settings")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(.bottom, 16)

                Text(
                    "\(KeychainHelper.loadCredentials().username ?? "-")"
                )
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.bottom, 16)
                
                Button("Reload") {
                    Task {
                        await model.fetchServerData()
                    }
                }

                Button("Log out") {
                    model.logout()
                }

                HStack {
                    Text(
                        "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")"
                    )

                    Text(
                        "#\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top, 16)
            }
        }
    }
}

#Preview("English") {
    Settings()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            ))
}

#Preview("German") {

    Settings()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            )
        )
        .environment(\.locale, Locale(identifier: "DE"))
}

#Preview("French") {

    Settings()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            )
        )
        .environment(\.locale, Locale(identifier: "FR"))
}

#Preview("Italian") {

    Settings()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            )
        )
        .environment(\.locale, Locale(identifier: "IT"))
}
