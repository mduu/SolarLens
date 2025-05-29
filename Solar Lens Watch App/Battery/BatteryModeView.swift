// 

import SwiftUI

struct BatteryModeView: View {
    let battery: Device
    
    var body: some View {
        
    }
}

#Preview {
    BatteryModeView(
        battery: Device(
            id: "1234",
            deviceType: .battery,
            name: "Test 1",
            priority: 1,
            batteryInfo: BatteryInfo(
                favorite: true,
                maxDischargePower: 7000,
                maxChargePower: 7000,
                batteryCapacityKwh: 11
            )
        )
    )
}
