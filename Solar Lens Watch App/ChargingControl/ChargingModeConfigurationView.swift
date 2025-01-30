import Combine
import SwiftUI

struct ChargingModeConfigurationView: View {
    var chargingModeConfiguration: ChargingModeConfiguration

    var body: some View {
        ScrollView {
            
            VStack(alignment: .leading) {
                
                Text("Personalize")
                    .font(.headline)
                    .foregroundColor(.accent)
                Divider()
                
                VStack(spacing: 15) {
                    
                    ForEach(ChargingMode.allCases, id: \.self) { mode in
                        
                        ModeToggle(
                            chargingModeConfiguration: chargingModeConfiguration,
                            chargingMode: mode)
                        
                    }  // :ForEach
                }  // :VStack
            } // :VStack
        }  // :ScrollView
    }  // :View
}

struct ModeToggle: View {
    var chargingModeConfiguration: ChargingModeConfiguration
    var chargingMode: ChargingMode

    var body: some View {
        Toggle(
            isOn: Binding(
                get: {
                    chargingModeConfiguration.chargingModeVisibillity[
                        chargingMode] ?? true
                },
                set: {
                    chargingModeConfiguration.changeChargingModeVisibillity(
                        mode: chargingMode, newValue: $0)
                }
            )
        ) {
            ChargingModelLabelView(chargingMode: chargingMode)
        }
    }
}

#Preview {
    ChargingModeConfigurationView(
        chargingModeConfiguration: ChargingModeConfiguration()
    )
}
