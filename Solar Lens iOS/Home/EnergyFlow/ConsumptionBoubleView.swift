import SwiftUI

struct ConsumptionBoubleView: View {
    var currentConsumptionInKwh: Double
    var todayConsumptionInWh: Double?
    var applyCardStyle: Bool = true

    @State var isDeviceSheetShown: Bool = false

    var body: some View {
        let todayKwh = (todayConsumptionInWh ?? 0) / 1000

        EnergyCard(
            icon: "house.fill",
            iconColor: .teal,
            label: "Consumption",
            value: String(format: "%.1f kW", currentConsumptionInKwh),
            detail: todayConsumptionInWh != nil ? String(format: "%.1f kWh today", todayKwh) : nil,
            showChevron: true,
            applyCardStyle: applyCardStyle
        )
        .onTapGesture { isDeviceSheetShown = true }
        .sheet(isPresented: $isDeviceSheetShown) {
            NavigationView {
                DevicePrioritySheet()
            }
            .presentationDetents([.large])
        }
    }
}

#Preview {
    ConsumptionBoubleView(
        currentConsumptionInKwh: 4.5,
        todayConsumptionInWh: 34595
    )
    .padding()
}
