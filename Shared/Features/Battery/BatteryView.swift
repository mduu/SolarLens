//

import SwiftUI

struct BatteryView: View {
    let battery: Device

    @State var showModeSheet: Bool = false

    var body: some View {
        Button(action: {
            showModeSheet = true
        }) {
            HStack {
                Image(systemName: "battery.100percent.circle")
                    .font(.title2)
                    .fontWeight(.thin)
                    #if os(watchOS)
                        .foregroundColor(.white.opacity(0.8))
                    #endif

                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {

                        Text(battery.name)
                            .font(.footnote)
                            #if os(watchOS)
                                .foregroundColor(.white.opacity(0.8))
                            #endif

                        Spacer()

                        if battery.currentPowerInWatts != 0 {
                            Text(
                                battery.currentPowerInWatts
                                    .formatWattsAsWattsKiloWatts(
                                        widthUnit: true
                                    )
                            )
                            .font(.footnote)
                            .foregroundColor(
                                battery.currentPowerInWatts < 0
                                    ? .orange
                                    : battery.currentPowerInWatts > 0
                                        ? .green
                                        : .white
                            )
                            .padding(.trailing, 2)
                        }
                    }

                    HStack {
                        Text(getBatteryModeText())
                    }
                }

                Spacer()
            }
        }
        #if os(iOS)
            .foregroundColor(.primary)
        #endif
        .tint(.purple)
        #if os(watchOS)
            .sheet(isPresented: $showModeSheet) {
                BatteryModeSheet(battery: battery)
                    .navigationTitle {
                        Text("Battery mode")
                            .foregroundColor(.purple)
                            .font(.headline)
                    }
            }
        #else
            .sheet(isPresented: $showModeSheet) {
                NavigationView {
                    BatteryModeSheet(battery: battery)
                    .navigationTitle("Battery mode")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                showModeSheet = false
                            }) {
                                Image(systemName: "xmark")  // Use a system icon
                                .resizable()  // Make the image resizable
                                .scaledToFit()  // Fit the image within the available space
                                .frame(width: 18, height: 18)  // Set the size of the image
                                .foregroundColor(.purple)  // Set the color of the image
                            }
                        }
                    }
                    .padding()
                }
                .presentationDetents([.medium])
            }
        #endif
    }

    func getBatteryModeText() -> LocalizedStringResource {
        switch battery.batteryInfo?.modeInfo.batteryMode {
        case .Standard:
            "Standard"
        case .Eco:
            "Eco"
        case .PeakShaving:
            "Peak shaving"
        case .Manual:
            "Manual"
        case .TariffOptimized:
            "Tariff optimized"
        case .StandardControlled:
            battery.batteryInfo?.modeInfo.standardStandaloneAllowed ?? false
                ? "Standalone"
                : "Standard"
        case nil:
            ""
        }
    }
}

#Preview {
    ZStack {

        #if os(watchOS)
            LinearGradient(
                gradient: Gradient(colors: [
                    .purple.opacity(0.4), .purple.opacity(0.1),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        #endif

        VStack {
            BatteryView(
                battery: Device(
                    id: "1234",
                    deviceType: .battery,
                    name: "Test 1",
                    priority: 1,
                    currentPowerInWatts: 3250,
                    batteryInfo: BatteryInfo.fake()
                )
            )
            .frame(maxHeight: 60)

            Spacer()
        }
    }

}
