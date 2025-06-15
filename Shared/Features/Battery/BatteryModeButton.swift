import SwiftUI

struct BatteryModeButton: View {
    let battery: Device
    let mode: BatteryMode

    @State var showBatteryModeOptions = false

    var body: some View {
        let isActiveButton = battery.batteryInfo?.modeInfo.batteryMode == mode
        let modeName = mode.GetBatteryModeName()
        
        #if os(watchOS)
        let activeTint: Color = .purple.opacity(0.6)
        let inactiveTint: Color = .white.opacity(0.3)
        #else
        let activeTint: Color = .purple
        let inactiveTint: Color = .purple.opacity(0.8)
        #endif

        Button(action: {
            showBatteryModeOptions = true
        }) {
            HStack(alignment: .top) {
                Spacer()
                
                if isActiveButton {
                    Image(systemName: "checkmark.circle.fill")
                }

                Text(modeName)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .tint(
            isActiveButton ? activeTint : inactiveTint
        )
        #if os(watchOS)
        .sheet(
            isPresented: $showBatteryModeOptions) {
                
            BatteryModeOptionsSheet(
                battery: battery,
                targetMode: mode
            )
        }
        #else
            .sheet(isPresented: $showBatteryModeOptions) {
                   
                NavigationView {
                    
                    BatteryModeOptionsSheet(
                        battery: battery,
                        targetMode: mode
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                showBatteryModeOptions = false
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
}

#Preview {
    BatteryModeButton(
        battery: .fakeBattery(),
        mode: .StandardControlled
    )
    
    BatteryModeButton(
        battery: .fakeBattery(),
        mode: .Eco
    )
    
    BatteryModeButton(
        battery: .fakeBattery(),
        mode: .Standard
    )
}
