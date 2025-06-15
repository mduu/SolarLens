import SwiftUI

struct BatteryList: View {
    let batteryDevices: [Device]

    var body: some View {
        Group {
            
            List {
                
                ForEach(batteryDevices) { battery in
                    BatteryView(battery: battery)
                }
                
            }
            .listStyle(.inset)
            .listRowSeparator(.visible, edges: [.all])
        }
    }
}

#Preview {
    VStack {
        BatteryList(
            batteryDevices: [
                Device.fakeBattery(
                    id: "1",
                    name: "Bat 1",
                    priority: 0,
                    currentPowerInWatts: 3600
                ),
                Device.fakeBattery(
                    id: "2",
                    name: "Bat 2",
                    priority: 1,
                    currentPowerInWatts: 1220
                ),
            ]
        )
        
        Spacer()
    }
}
