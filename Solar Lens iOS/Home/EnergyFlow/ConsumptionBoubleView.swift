import SwiftUI

struct ConsumptionBoubleView: View {
    var currentConsumptionInKwh: Double
    var todayConsumptionInWh: Double?
    
    @State var isDeviceSheetShown: Bool = false

    var body: some View {

        CircularInstrument(
            borderColor: currentConsumptionInKwh != 0 ? .teal : .gray,
            label: "Consumption",
            value: String(
                format: "%.1f kW", currentConsumptionInKwh)
        ) {
            VStack {
                if todayConsumptionInWh != nil {
                    TodayValue(valueInWh: todayConsumptionInWh!)
                }

                Image(systemName: "house")
                    .foregroundColor(.black)
                    .padding(.top, 1)

            }
        }
        .onTapGesture
        {
            isDeviceSheetShown = true
        }
        .sheet(isPresented: $isDeviceSheetShown)
        {
            NavigationView {
                DevicePrioritySheet()
            }
            .presentationDetents([.medium, .large]) 
        }
    }
}

#Preview("No autarchy") {
    VStack {
        HStack {
            ConsumptionBoubleView(
                currentConsumptionInKwh: 4.5,
                todayConsumptionInWh: 34595
            )
            .frame(width: 120, height: 120)

            Spacer()
        }

        Spacer()
    }
}
